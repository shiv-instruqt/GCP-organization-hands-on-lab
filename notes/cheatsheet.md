# Hints & cheat sheet

## Concepts in one screen

| Term | One-liner |
|------|-----------|
| Organization / folder / project | Hierarchy; policies set higher are **inherited** by everything below |
| Project ID / number | ID = your unique name; number = Google's numeric ID (used in service-agent emails) |
| Principal | Who: user, group, service account, federated identity, domain |
| Role | Bundle of permissions. Basic (avoid) → Predefined → Custom |
| Binding | principal + role (+ condition) attached to a resource |
| Service account (SA) | Identity for a workload. Is **both** a principal and a resource |
| Impersonation | Get a short-lived token for an SA. Needs `roles/iam.serviceAccountTokenCreator` **on that SA** |
| actAs | Attach an SA to a resource (Cloud Run, VM...). Needs `roles/iam.serviceAccountUser` **on that SA** |
| IAM Condition | CEL expression on a binding (time, resource name/type). Policy version 3 |
| Org policy | Guard-rail constraint (what is allowed at all) — independent of IAM |
| Quota | Per-project/per-region limit for an API |

## gcloud configurations

```bash
gcloud config configurations list | create NAME | activate NAME
gcloud --configuration=NAME <command>          # one-off
gcloud config list                              # what's active
gcloud auth list                                # credentialed accounts
```

## APIs

```bash
gcloud services list --enabled
gcloud services list --available --filter="name:run"
gcloud services enable  API [API...]
gcloud services disable API --force
```

## IAM — project / bucket / service account

```bash
gcloud projects get-iam-policy P --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
gcloud projects add-iam-policy-binding    P --member=serviceAccount:EMAIL --role=ROLE --condition=None
gcloud projects remove-iam-policy-binding P --member=serviceAccount:EMAIL --role=ROLE --all

gcloud storage buckets add-iam-policy-binding gs://B --member=... --role=...
gcloud iam service-accounts add-iam-policy-binding SA_EMAIL --member=... --role=...
```

## Roles

```bash
gcloud iam roles describe roles/storage.objectViewer
gcloud iam roles create ID --project=P --permissions=a,b,c --stage=GA --title="..."
gcloud iam roles update ID --project=P --add-permissions=x | --remove-permissions=x
gcloud iam roles list --project=P
```

## Service accounts & impersonation

```bash
gcloud iam service-accounts create NAME --display-name="..."
gcloud iam service-accounts keys list --iam-account=EMAIL --managed-by=user
<any gcloud command> --impersonate-service-account=EMAIL
```

## IAM Conditions

```bash
--condition="expression=request.time < timestamp('2026-12-31T00:00:00Z'),title=temp-access,description=..."
--condition="expression=resource.name.startsWith('projects/_/buckets/my-bucket'),title=one-bucket"
```

## Policy Troubleshooter

```bash
gcloud policy-intelligence troubleshoot-policy iam FULL_RESOURCE_NAME \
  --principal-email=EMAIL --permission=PERMISSION
# project : //cloudresourcemanager.googleapis.com/projects/PROJECT_ID
# bucket  : //storage.googleapis.com/projects/_/buckets/BUCKET
# SA      : //iam.googleapis.com/projects/PROJECT_ID/serviceAccounts/EMAIL
```

## Org policies

```bash
gcloud org-policies list --project=P [--show-unset]
gcloud org-policies describe CONSTRAINT --project=P --effective
```

## Shell variables available in every terminal

`$DEV_PROJECT` `$STAGING_PROJECT` `$DEV_ADMIN_SA` `$STAGING_ADMIN_SA` `$DEV_BUCKET` `$DEV_ALICE` `$CI_DEPLOYER` `$APP_RUNTIME` `$LAB_REGION`
