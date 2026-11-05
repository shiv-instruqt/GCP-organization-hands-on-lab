#!/bin/bash
# -----------------------------------------------------------------------------
# Week 1 lab bootstrap (runs once in the cloud_cli container at lab start)
#
#  1. Writes /opt/lab/env.sh + /opt/lab/lib.sh (used by the task check scripts)
#  2. Creates a PRIVATE gcloud config for the checkers (/opt/lab/gcloud), so
#     whatever the learner does to their own gcloud config never breaks checks
#  3. Makes the projects "fresh": disables the APIs the learner must enable
#  4. Creates ~/week1 note templates (the end-of-week deliverable lives here)
#  5. Adds a prompt that always shows the ACTIVE gcloud identity and an
#     automatic command log (~/week1/commands.log) of every gcloud command,
#     which identity ran it, and whether it succeeded.
#
# The learner's own gcloud is intentionally left UNAUTHENTICATED.
# -----------------------------------------------------------------------------
set -uo pipefail

log() { echo "[bootstrap] $*"; }

LAB_DIR=/opt/lab
WEEK1=/root/week1
mkdir -p "$LAB_DIR" "$WEEK1"

# Learner-enabled APIs (they are on the sandbox allow-list, but start disabled)
DISABLE_APIS="iamcredentials.googleapis.com policytroubleshooter.googleapis.com orgpolicy.googleapis.com artifactregistry.googleapis.com run.googleapis.com"

# --- 0. wait for the service-account keys to be mounted ---------------------
for _ in $(seq 1 90); do
  if [ -s /root/.keys/dev-platform-admin.json ] && [ -s /root/.keys/staging-platform-admin.json ]; then
    break
  fi
  sleep 2
done

# Small tools (best effort - the checks only need python3, which gcloud ships)
apk add --no-cache jq less >/dev/null 2>&1 || true

# --- 1. env + helper library for check scripts ------------------------------
cat > "$LAB_DIR/env.sh" <<EOF
export DEV_PROJECT="${DEV_PROJECT}"
export STAGING_PROJECT="${STAGING_PROJECT}"
export DEV_ADMIN_SA="${DEV_ADMIN_SA}"
export STAGING_ADMIN_SA="${STAGING_ADMIN_SA}"
export LAB_REGION="${LAB_REGION:-us-central1}"
export DEV_BUCKET="${DEV_PROJECT}-app-data"
export DEV_ALICE="dev-alice@${DEV_PROJECT}.iam.gserviceaccount.com"
export CI_DEPLOYER="ci-deployer@${STAGING_PROJECT}.iam.gserviceaccount.com"
export APP_RUNTIME="app-runtime@${STAGING_PROJECT}.iam.gserviceaccount.com"
EOF
chmod 644 "$LAB_DIR/env.sh"

cat > "$LAB_DIR/lib.sh" <<'EOF'
# Shared helpers for task check/solve scripts
source /opt/lab/env.sh
export HOME=/root
export CLOUDSDK_CORE_DISABLE_PROMPTS=1
LOG=/root/week1/commands.log
W1=/root/week1

# gcloud as the checker (never touches the learner's ~/.config/gcloud)
gck()  { CLOUDSDK_CONFIG=/opt/lab/gcloud gcloud --quiet "$@"; }
gdev() { gck --account="$DEV_ADMIN_SA" --project="$DEV_PROJECT" "$@"; }
gstg() { gck --account="$STAGING_ADMIN_SA" --project="$STAGING_PROJECT" "$@"; }

fail() { echo "$*"; exit 1; }

# Reads an IAM policy (JSON) on stdin and prints one line per binding that
# contains MEMBER:   role<TAB>condition-title<TAB>condition-expression
_bindings_for() {
  python3 -c '
import json, sys
member = sys.argv[1]
try:
    policy = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for b in policy.get("bindings", []):
    if member in b.get("members", []):
        c = b.get("condition") or {}
        print("%s\t%s\t%s" % (b.get("role", ""), c.get("title", ""), " ".join(c.get("expression", "").split())))
' "$1"
}

# project_bindings <gdev|gstg> <project> <member>   -> role<TAB>title<TAB>expression
project_bindings() { "$1" projects get-iam-policy "$2" --format=json 2>/dev/null | _bindings_for "$3"; }
project_roles()    { project_bindings "$@" | cut -f1; }

# sa_roles <gdev|gstg> <sa-email> <member>
sa_roles() { "$1" iam service-accounts get-iam-policy "$2" --format=json 2>/dev/null | _bindings_for "$3" | cut -f1; }

# bucket_roles <bucket> <member>
bucket_roles() { gdev storage buckets get-iam-policy "gs://$1" --format=json 2>/dev/null | _bindings_for "$2" | cut -f1; }

# custom_role_perms <gdev|gstg> <role-id>   -> one permission per line (empty if missing/deleted)
custom_role_perms() {
  "$1" iam roles describe "$2" --project="$( [ "$1" = gdev ] && echo "$DEV_PROJECT" || echo "$STAGING_PROJECT")" --format=json 2>/dev/null |
    python3 -c '
import json, sys
try:
    r = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not r.get("deleted"):
    print("\n".join(r.get("includedPermissions", [])))
'
}

sa_exists() { "$1" iam service-accounts describe "$2" --format="value(email)" >/dev/null 2>&1; }

api_enabled() { # api_enabled <gdev|gstg> <api>
  "$1" services list --enabled --format="value(config.name)" 2>/dev/null | grep -qx "$2"
}

no_todo() { # no_todo <file>
  [ -f "$1" ] || return 1
  ! grep -q "_TODO_" "$1"
}

# --- command-log helpers (log line: ts | config=.. | account=.. | acting-as=.. | exit=N | cmd)
log_ok_as()     { grep -F "| acting-as=$1 | exit=0 |" "$LOG" 2>/dev/null | grep -q "gcloud"; }
log_denied_as() { grep -F "| acting-as=$1 |" "$LOG" 2>/dev/null | grep -Eq '\| exit=[1-9][0-9]* \|'; }
log_note()      { printf '%s | config=auto-solve | account=%s | acting-as=%s | exit=%s | %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" "$2" "$1" "$3" >> "$LOG"; }
EOF
chmod 644 "$LAB_DIR/lib.sh"

# --- 2. private checker gcloud config ---------------------------------------
export CLOUDSDK_CONFIG="$LAB_DIR/gcloud"
mkdir -p "$CLOUDSDK_CONFIG"
gcloud auth activate-service-account --key-file=/root/.keys/dev-platform-admin.json --quiet
gcloud auth activate-service-account --key-file=/root/.keys/staging-platform-admin.json --quiet
gcloud config set core/disable_usage_reporting true --quiet >/dev/null 2>&1
gcloud config set core/disable_prompts true --quiet >/dev/null 2>&1

# --- 3. make the projects "fresh" -------------------------------------------
disable_apis() { # disable_apis <account> <project>
  local acct=$1 proj=$2
  for attempt in 1 2 3 4 5 6; do
    # shellcheck disable=SC2086
    if gcloud services disable $DISABLE_APIS --account="$acct" --project="$proj" --force --quiet >/dev/null 2>&1; then
      log "fresh APIs ready in $proj"
      return 0
    fi
    log "IAM still propagating in $proj, retry $attempt/6..."
    sleep 15
  done
  log "WARNING: could not disable learner APIs in $proj (they may already be enabled)"
}
disable_apis "$DEV_ADMIN_SA" "$DEV_PROJECT"
disable_apis "$STAGING_ADMIN_SA" "$STAGING_PROJECT"
unset CLOUDSDK_CONFIG

# --- 4. ~/week1 note templates ----------------------------------------------
cat > "$WEEK1/00-environment.md" <<EOF
# Your lab environment (generated - read only reference)

| Item | Value |
|------|-------|
| Dev project ID | \`${DEV_PROJECT}\` |
| Staging project ID | \`${STAGING_PROJECT}\` |
| Region | \`${LAB_REGION:-us-central1}\` |
| Dev bootstrap identity (platform admin) | \`${DEV_ADMIN_SA}\` |
| Staging bootstrap identity (platform admin) | \`${STAGING_ADMIN_SA}\` |
| Dev key file | \`/root/.keys/dev-platform-admin.json\` |
| Staging key file | \`/root/.keys/staging-platform-admin.json\` |

Handy shell variables (already exported in every terminal):
\`\$DEV_PROJECT\`, \`\$STAGING_PROJECT\`, \`\$DEV_ADMIN_SA\`, \`\$STAGING_ADMIN_SA\`,
\`\$DEV_BUCKET\`, \`\$DEV_ALICE\`, \`\$CI_DEPLOYER\`, \`\$APP_RUNTIME\`, \`\$LAB_REGION\`
EOF

cat > "$WEEK1/01-hierarchy.md" <<'EOF'
# 01 — Resource hierarchy notes

| Project | Project ID | Project NUMBER | Parent (folder/org) |
|---------|------------|----------------|---------------------|
| dev     | _TODO_     | _TODO_         | _TODO_              |
| staging | _TODO_     | _TODO_         | _TODO_              |

## Ancestors (output of `gcloud projects get-ancestors`)
_TODO_

## Billing — what did you see and why?
_TODO_

## What happened when you tried `gcloud projects create`? Why?
_TODO_
EOF

cat > "$WEEK1/02-api-enablement.md" <<'EOF'
# 02 — API enablement notes

Fill one row per API you enabled. "Enabled by" = the exact identity (email)
that was active when you ran the command (check your prompt / commands.log).

| API | Project | Why it is needed | Enabled by (identity) | Command |
|-----|---------|------------------|-----------------------|---------|
| _TODO_ | _TODO_ | _TODO_ | _TODO_ | _TODO_ |

## APIs that were already enabled when you started (and why that matters)
_TODO_
EOF

cat > "$WEEK1/03-identity-map.md" <<'EOF'
# 03 — Identity map

| Identity (email) | Type (human / workload / bootstrap) | Home project | Represents | Can act on | How it authenticates |
|------------------|-------------------------------------|--------------|------------|------------|----------------------|
| _TODO_ | _TODO_ | _TODO_ | _TODO_ | _TODO_ | _TODO_ |

## Who can impersonate whom?
_TODO_

## Why are there NO user-managed keys for dev-alice / ci-deployer?
_TODO_
EOF

cat > "$WEEK1/04-org-policy-quotas.md" <<'EOF'
# 04 — Org policies, project boundaries & quotas

## Effective org policies I inspected (constraint -> effective value -> impact)
_TODO_

## Project boundary test (what was denied, by which identity, and why)
_TODO_

## Quota I looked up (service, metric, limit) and how I would raise it
_TODO_
EOF

cat > "$WEEK1/05-failure-drill.md" <<'EOF'
# 05 — Failure drill

## 1. What I removed
_TODO_

## 2. The error the developer saw (paste it)
_TODO_

## 3. What Policy Troubleshooter said (summary - full output in 05-troubleshooter.txt)
_TODO_

## 4. Broad fix vs narrow fix
| Option | Role / change | Permissions granted (count) | Risk |
|--------|---------------|-----------------------------|------|
| Broad  | _TODO_ | _TODO_ | _TODO_ |
| Narrow | _TODO_ | _TODO_ | _TODO_ |

## 5. Which one did I keep, and why?
_TODO_
EOF

cat > "$WEEK1/06-least-privilege.md" <<'EOF'
# 06 — Least-privilege table

| Identity | Task it must perform | Narrowest role (and scope: project / bucket / SA) | Broad role I avoided | Condition (if any) |
|----------|----------------------|---------------------------------------------------|----------------------|--------------------|
| _TODO_ | _TODO_ | _TODO_ | _TODO_ | _TODO_ |
EOF

touch "$WEEK1/commands.log"

# --- 5. shell: identity-aware prompt + automatic command log ----------------
cat > /root/.lab_shell.sh <<'EOF'
# >>> week1 lab shell >>>
source /opt/lab/env.sh
export PATH="$PATH"
shopt -s histappend 2>/dev/null
export HISTFILE=/root/.bash_history HISTSIZE=10000 HISTFILESIZE=20000

# Active gcloud configuration + account, read straight from the config files (fast)
__lab_identity() {
  local cfg f acct
  cfg="${CLOUDSDK_ACTIVE_CONFIG_NAME:-$(cat /root/.config/gcloud/active_config 2>/dev/null || echo default)}"
  f="/root/.config/gcloud/configurations/config_${cfg}"
  acct="$(awk -F' *= *' '/^account/ {print $2; exit}' "$f" 2>/dev/null)"
  __LAB_IMP="$(awk -F' *= *' '/^impersonate_service_account/ {print $2; exit}' "$f" 2>/dev/null)"
  __LAB_CFG="$cfg"
  __LAB_ACCT="${acct:-<not-authenticated>}"
}

# Append every gcloud / curl command to ~/week1/commands.log with the identity used
__lab_log() {
  local rc=$1 n cmd as
  read -r n cmd <<< "$(HISTTIMEFORMAT= history 1)"
  [ -z "${n:-}" ] && return
  [ "$n" = "${__LAB_LAST_N:-}" ] && return
  __LAB_LAST_N="$n"
  case "$cmd" in
    *gcloud*|*curl*) ;;
    *) return ;;
  esac
  # identity active when the command STARTED (computed at the previous prompt)
  local cfg="$__LAB_CFG" acct="$__LAB_ACCT" imp="${__LAB_IMP:-}" oc
  # one-off --configuration=NAME overrides the active configuration
  oc="$(grep -oE -- '--configuration[= ][^ ]+' <<< "$cmd" | sed -E 's/--configuration[= ]//; s/["'"'"']//g' | head -1)"
  if [ -n "$oc" ] && [ -f "/root/.config/gcloud/configurations/config_${oc}" ]; then
    cfg="$oc"
    acct="$(awk -F' *= *' '/^account/ {print $2; exit}' "/root/.config/gcloud/configurations/config_${oc}")"
    imp="$(awk -F' *= *' '/^impersonate_service_account/ {print $2; exit}' "/root/.config/gcloud/configurations/config_${oc}")"
  fi
  # who did the API calls? flag > config-level impersonation > account
  as="$(grep -oE -- '--impersonate-service-account[= ][^ ]+' <<< "$cmd" | sed -E 's/--impersonate-service-account[= ]//; s/["'"'"']//g' | head -1)"
  # expand $VARS like $DEV_ALICE so the log shows real emails
  case "$as" in \$*) as="$(eval echo "$as" 2>/dev/null)";; esac
  printf '%s | config=%s | account=%s | acting-as=%s | exit=%s | %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$cfg" "${acct:-<not-authenticated>}" "${as:-${imp:-${acct:-<not-authenticated>}}}" "$rc" "$cmd" \
    >> /root/week1/commands.log
}

__lab_prompt() {
  local rc=$?
  history -a
  __lab_log "$rc"
  __lab_identity
  local short="${__LAB_ACCT%%@*}"
  PS1="\[\e[1;36m\][gcloud: ${__LAB_CFG} | ${short}]\[\e[0m\] \w \$ "
}
__lab_identity
PROMPT_COMMAND=__lab_prompt

if [ -z "${__LAB_BANNER_SHOWN:-}" ]; then
  export __LAB_BANNER_SHOWN=1
  echo ""
  echo "  Week 1 lab - GCP organization, projects and identity"
  echo "  ----------------------------------------------------"
  echo "  Dev project     : $DEV_PROJECT"
  echo "  Staging project : $STAGING_PROJECT"
  echo "  Your notes      : ~/week1   (every gcloud command is logged to ~/week1/commands.log)"
  echo "  The prompt shows the ACTIVE gcloud configuration and identity."
  echo ""
fi
# <<< week1 lab shell <<<
EOF

grep -q ".lab_shell.sh" /root/.bashrc 2>/dev/null || echo '[ -f /root/.lab_shell.sh ] && source /root/.lab_shell.sh' >> /root/.bashrc
grep -q ".bashrc" /root/.bash_profile 2>/dev/null || echo '[ -f /root/.bashrc ] && source /root/.bashrc' >> /root/.bash_profile

log "done"
exit 0
