# 2.2 Act as the developer with impersonation

## Concept: service account impersonation

Instead of downloading a key for `dev-alice`, a trusted principal can **impersonate** it: it asks the *IAM Service Account Credentials API* for a **short-lived token** (1 hour by default).

```text
platform-admin ──(roles/iam.serviceAccountTokenCreator ON dev-alice)──► token for dev-alice ──► Cloud Storage
```

- The permission is `iam.serviceAccounts.getAccessToken`, granted by **Service Account Token Creator**.
- Grant it **on the service account resource**, not on the project — otherwise the grantee can impersonate *every* service account in the project.
- Every impersonated call is audit-logged with **both** identities (the caller and the service account).
- No keys to leak, rotate or forget. This is how humans and CI systems should "become" a workload identity.

## Your goal

1. Allow **only** the dev `platform-admin` to impersonate `dev-alice` — grant on the `dev-alice` service account, not the project.
2. As `dev-alice`, upload `hello.txt` to `$DEV_BUCKET` and list the bucket.
3. As `dev-alice`, try at least one thing the role does **not** allow and confirm it is denied.

### Step 1 — Try impersonating before you are allowed to

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud config configurations activate dev
gcloud storage ls "gs://$DEV_BUCKET" --impersonate-service-account="$DEV_ALICE"
```

Expected error: `Permission 'iam.serviceAccounts.getAccessToken' denied`. Being *Service Account Admin* lets you manage service accounts — it does **not** let you act as them. That separation is deliberate.

</details>

### Step 2 — Grant Token Creator on the service account

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud iam service-accounts add-iam-policy-binding "$DEV_ALICE" \
  --member="serviceAccount:$DEV_ADMIN_SA" \
  --role="roles/iam.serviceAccountTokenCreator"

gcloud iam service-accounts get-iam-policy "$DEV_ALICE"
```

Wait ~60 seconds for the grant to propagate.

</details>

### Step 3 — Work as `dev-alice`

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
echo "hello from alice" > ~/week1/hello.txt

# allowed: upload (objects.create) and list (objects.list)
gcloud storage cp ~/week1/hello.txt "gs://$DEV_BUCKET/hello.txt" --impersonate-service-account="$DEV_ALICE"
gcloud storage ls "gs://$DEV_BUCKET"                              --impersonate-service-account="$DEV_ALICE"
gcloud storage cat "gs://$DEV_BUCKET/hello.txt"                   --impersonate-service-account="$DEV_ALICE"
```

The yellow `WARNING: This command is using service account impersonation` line is expected.

</details>

### Step 4 — Prove what `dev-alice` can NOT do

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
# delete -> denied (no storage.objects.delete)
gcloud storage rm "gs://$DEV_BUCKET/hello.txt" --impersonate-service-account="$DEV_ALICE"

# overwrite the same object -> denied (overwriting needs storage.objects.delete too!)
gcloud storage cp ~/week1/hello.txt "gs://$DEV_BUCKET/hello.txt" --impersonate-service-account="$DEV_ALICE"

# list buckets in the project -> denied (no project-level role at all)
gcloud storage buckets list --project="$DEV_PROJECT" --impersonate-service-account="$DEV_ALICE"
```

Check `~/week1/commands.log`: each line shows `acting-as=dev-alice@…` and the exit code. That's your audit trail for the identity map.

</details>

> [!NOTE]
> To impersonate for a whole session: `gcloud config set auth/impersonate_service_account $DEV_ALICE` — and **always** `gcloud config unset auth/impersonate_service_account` afterwards.

## Checklist

<instruqt-task id="t_impersonate_dev"></instruqt-task>

## Knowledge check

<instruqt-quiz id="quiz_iam"></instruqt-quiz>
