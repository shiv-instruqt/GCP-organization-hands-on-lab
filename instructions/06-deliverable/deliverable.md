# 6. End-of-week deliverable

You built it — now prove you understand it. The deliverable has four parts, all in `~/week1`:

| Part | File |
|------|------|
| **Identity map** | `03-identity-map.md` |
| **API enablement notes** | `02-api-enablement.md` (done in chapter 1) |
| **CLI commands** (with the identity that ran each one) | `commands.log` (automatic) |
| **Least-privilege table** | `06-least-privilege.md` |

Plus your supporting notes: `01-hierarchy.md`, `04-org-policy-quotas.md`, `05-failure-drill.md`.

## Your goal

1. Complete the **identity map** — one row for **every** identity in the lab (all five service accounts **and** your console user). Answer the two questions under the table.
2. Complete the **least-privilege table** — one row per identity, with the narrowest role, its **scope** (project / bucket / service account), the broad role you avoided and any condition.
3. Bundle everything into **`~/week1/week1-deliverable.md`**.

### Step 1 — Collect the facts from the live environment

Use `gcloud` to list every identity and every binding rather than writing from memory.

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
# all service accounts in both projects
gcloud --configuration=dev     iam service-accounts list --format="table(email, displayName)"
gcloud --configuration=staging iam service-accounts list --format="table(email, displayName)"

# project-level bindings (look for your identities, ignore Google service agents)
for c in dev staging; do
  p=$(gcloud --configuration=$c config get-value project 2>/dev/null)
  echo "=== $c ($p)"
  gcloud --configuration=$c projects get-iam-policy "$p" --flatten="bindings[].members" \
    --format="table(bindings.role, bindings.members, bindings.condition.title)"
done

# resource-level bindings
gcloud --configuration=dev     storage buckets get-iam-policy "gs://$DEV_BUCKET"
gcloud --configuration=dev     iam service-accounts get-iam-policy "$DEV_ALICE"
gcloud --configuration=staging iam service-accounts get-iam-policy "$CI_DEPLOYER"
gcloud --configuration=staging iam service-accounts get-iam-policy "$APP_RUNTIME"

# your command log, grouped by acting identity
cut -d'|' -f4 ~/week1/commands.log | sort | uniq -c
```

</details>

### Step 2 — Fill the identity map and least-privilege table

<details>
<summary>💡 Show an example row for each table</summary>

Identity map:

| Identity (email) | Type | Home project | Represents | Can act on | How it authenticates |
|---|---|---|---|---|---|
| `dev-alice@<dev>.iam.gserviceaccount.com` | human stand-in | dev | Alice, developer | `gs://<dev>-app-data` (appDeveloper); staging objects read-only until expiry | Impersonated by dev platform-admin (short-lived token), no keys |

Least-privilege table:

| Identity | Task | Narrowest role (scope) | Broad role avoided | Condition |
|---|---|---|---|---|
| ci-deployer | Deploy Cloud Run in staging | `roles/run.developer` (project) + `roles/iam.serviceAccountUser` (on app-runtime only) | `roles/run.admin`, `roles/editor`, project-wide serviceAccountUser | — |

Don't forget: `app-runtime`, both `platform-admin` accounts, `roles/iam.serviceAccountTokenCreator` grants, the conditional `roles/storage.objectViewer`, and the console `learner` user.

</details>

### Step 3 — Bundle the deliverable

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
cd ~/week1
{
  echo "# Week 1 deliverable - GCP organization, projects and identity"
  echo "_Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)_"
  for f in 03-identity-map.md 02-api-enablement.md 06-least-privilege.md \
           01-hierarchy.md 04-org-policy-quotas.md 05-failure-drill.md; do
    echo; cat "$f"
  done
  echo; echo "## CLI command log (identity per command)"; echo '```text'; cat commands.log; echo '```'
} > week1-deliverable.md

wc -l week1-deliverable.md
```

Open it in the **Week 1 Notes (editor)** tab to review — and download it from there to submit.

</details>

## Checklist

<instruqt-task id="t_deliverable"></instruqt-task>

## Final knowledge check

<instruqt-quiz id="quiz_final"></instruqt-quiz>

## Recap

- The **hierarchy** (org → folder → project → resource) decides where policies are set and inherited; **projects** are the boundary for APIs, quotas, billing and IAM.
- **Predefined** roles first, **custom** roles when nothing is narrow enough — and always grant at the **smallest scope**.
- **Service accounts** are identities for workloads; humans and CI should **impersonate** them, not hold keys.
- **`actAs`** and **Token Creator** are powerful — grant them on single service accounts, never project-wide.
- **IAM Conditions** make access expire or apply to subsets of resources.
- **Org policies** are guard-rails above IAM that project admins can't override.
- When access is denied: read the error, run **Policy Troubleshooter**, add the **one** missing permission.

<instruqt-completion heading="Week 1 complete — your foundation is least-privilege!" finish-button-label="Finish lab"></instruqt-completion>
