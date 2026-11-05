# 5. Failure drill — break it, diagnose it, fix it narrowly

## Why this matters

"Access denied" is the most common ticket in any cloud team. The wrong reflex is to grant a **broad** role until the error goes away. The right one is to **find the exact missing permission** and grant the **narrowest** thing that contains it.

**Policy Troubleshooter** evaluates every allow (and deny) policy that applies to a principal + permission + resource and tells you *which binding* would grant it and *why it didn't*.

```text
principal  +  permission  +  full resource name   ──►  CAN_ACCESS / CANNOT_ACCESS  + explanation per policy & binding
```

## Your goal

1. **Break:** remove `storage.objects.list` from the `appDeveloper` custom role.
2. **Observe:** as `dev-alice`, listing the bucket fails. Capture the error.
3. **Diagnose:** run Policy Troubleshooter and save the output to `~/week1/05-troubleshooter.txt`.
4. **Compare:** fix it *broadly* with `roles/storage.admin` on the bucket — then **remove** that grant.
5. **Fix narrowly:** add only `storage.objects.list` back to `appDeveloper`.
6. Document the comparison in `~/week1/05-failure-drill.md`.

### Step 1 — Break it

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud config configurations activate dev

# baseline: works
gcloud storage ls "gs://$DEV_BUCKET" --impersonate-service-account="$DEV_ALICE"

# remove ONE permission from the custom role
gcloud iam roles update appDeveloper --project="$DEV_PROJECT" --remove-permissions=storage.objects.list
```

Custom-role changes can take **1–7 minutes** to propagate. Retry the next step until it fails.

</details>

### Step 2 — Observe the denial

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud storage ls "gs://$DEV_BUCKET" --impersonate-service-account="$DEV_ALICE"
# -> HTTPError 403: dev-alice@... does not have storage.objects.list access to the Google Cloud Storage bucket.
```

Paste the error into section 2 of `05-failure-drill.md`. Notice the error **names the missing permission** — always read it carefully.

</details>

### Step 3 — Diagnose with Policy Troubleshooter

<details>
<summary>💡 Show step-by-step instructions</summary>

CLI:

```bash
gcloud policy-intelligence troubleshoot-policy iam \
  "//storage.googleapis.com/projects/_/buckets/$DEV_BUCKET" \
  --principal-email="$DEV_ALICE" \
  --permission=storage.objects.list \
  | tee ~/week1/05-troubleshooter.txt
```

How to read it:
- `overallAccessState: CANNOT_ACCESS` — the verdict.
- `allowPolicyExplanation.explainedPolicies[]` — one entry per policy in the hierarchy (bucket, project, folder, org).
- In the **bucket** policy you'll see the `appDeveloper` binding: the principal **matches**, but the role does **not include** the permission (`rolePermission: ROLE_PERMISSION_NOT_INCLUDED`).
- No other policy grants it → denied.

Console (optional): *GCP Console* tab → **IAM & Admin → Policy Troubleshooter** (log in with the *Console Login* credentials). Principal = `dev-alice` email, resource = `//storage.googleapis.com/projects/_/buckets/<your bucket>`, permission = `storage.objects.list`.

</details>

### Step 4 — The broad fix (and why you'll undo it)

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud iam roles describe roles/storage.admin --format="value(includedPermissions)" | tr ';' '\n' | wc -l

gcloud storage buckets add-iam-policy-binding "gs://$DEV_BUCKET" \
  --member="serviceAccount:$DEV_ALICE" --role="roles/storage.admin"

# after ~60s: it "works"...
gcloud storage ls "gs://$DEV_BUCKET" --impersonate-service-account="$DEV_ALICE"
# ...but Alice can now also DELETE the bucket's objects, change its IAM policy (= grant anyone access) etc.
gcloud storage buckets get-iam-policy "gs://$DEV_BUCKET" --impersonate-service-account="$DEV_ALICE"

# undo it
gcloud storage buckets remove-iam-policy-binding "gs://$DEV_BUCKET" \
  --member="serviceAccount:$DEV_ALICE" --role="roles/storage.admin"
```

</details>

### Step 5 — The narrow fix

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud iam roles update appDeveloper --project="$DEV_PROJECT" --add-permissions=storage.objects.list
gcloud iam roles describe appDeveloper --project="$DEV_PROJECT" --format="value(includedPermissions)"

# after propagation:
gcloud storage ls "gs://$DEV_BUCKET" --impersonate-service-account="$DEV_ALICE"

# confirm with the troubleshooter (save separately so the "before" evidence stays)
gcloud policy-intelligence troubleshoot-policy iam \
  "//storage.googleapis.com/projects/_/buckets/$DEV_BUCKET" \
  --principal-email="$DEV_ALICE" --permission=storage.objects.list \
  --format="value(overallAccessState)" | tee ~/week1/05-troubleshooter-after.txt
```

Fill in `05-failure-drill.md` — including the permission counts for *Broad* (`storage.admin`) vs *Narrow* (`appDeveloper`).

</details>

## Checklist

<instruqt-task id="t_drill"></instruqt-task>
