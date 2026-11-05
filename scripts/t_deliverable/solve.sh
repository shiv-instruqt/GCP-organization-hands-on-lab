#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

case "$CHECK" in
  identity_map)
    cat > "$W1/03-identity-map.md" <<NOTES
# 03 — Identity map (auto-solved)

| Identity (email) | Type | Home project | Represents | Can act on | How it authenticates |
|---|---|---|---|---|---|
| $DEV_ADMIN_SA | bootstrap | dev | platform team | dev IAM, SAs, APIs, storage | key (lab bootstrap only) |
| $STAGING_ADMIN_SA | bootstrap | staging | platform team | staging IAM, SAs, APIs | key (lab bootstrap only) |
| $DEV_ALICE | human stand-in | dev | developer Alice | dev bucket (appDeveloper); staging objects read until expiry | impersonated by dev platform-admin |
| $CI_DEPLOYER | workload | staging | CI/CD pipeline | deploy Cloud Run, push images | impersonated (WIF in production) |
| $APP_RUNTIME | workload | staging | running app | nothing yet | attached to Cloud Run service |
| learner (console user) | human | both | you | read-only | password login |
NOTES
    ;;
  least_privilege)
    cat > "$W1/06-least-privilege.md" <<'NOTES'
# 06 — Least-privilege table (auto-solved)

| Identity | Task | Narrowest role (scope) | Broad role avoided | Condition |
|---|---|---|---|---|
| dev-alice | read/upload app data | appDeveloper (bucket) | roles/storage.admin, roles/editor | - |
| dev-alice | QA read in staging | roles/storage.objectViewer (staging project) | roles/viewer | request.time expiry |
| ci-deployer | deploy | roles/run.developer + roles/artifactregistry.writer (project) | roles/run.admin, roles/editor | - |
| ci-deployer | actAs runtime | roles/iam.serviceAccountUser (on app-runtime) | project-wide serviceAccountUser | - |
| platform-admin | impersonate | roles/iam.serviceAccountTokenCreator (on dev-alice / ci-deployer) | project-wide serviceAccountTokenCreator | - |
NOTES
    ;;
  command_log)
    for i in $(seq 1 15); do log_note 0 "$DEV_ADMIN_SA" "gcloud projects describe $DEV_PROJECT   # (auto-solved $i)"; done ;;
  bundled)
    cd "$W1" || exit 1
    { echo "# Week 1 deliverable"; for f in 03-identity-map.md 02-api-enablement.md 06-least-privilege.md 01-hierarchy.md 04-org-policy-quotas.md 05-failure-drill.md; do echo; cat "$f"; done
      echo; echo "## CLI command log"; cat commands.log; } > week1-deliverable.md ;;
esac
exit 0
