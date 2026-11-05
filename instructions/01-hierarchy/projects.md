# 1.1 Explore the hierarchy & set up your CLI identities

## Concept: the resource hierarchy

```text
Organization (example.com)          <- org policies + IAM set here apply to EVERYTHING below
 └── Folder (e.g. "payments")       <- group projects per team / environment
      ├── Project: dev              <- the unit of isolation: APIs, billing link, quotas, IAM
      │    └── Resources (buckets, service accounts, Cloud Run services ...)
      └── Project: staging
```

- **IAM is inherited downwards.** A role granted on a folder applies to every project in it. You can *add* access lower down, but you can't take away access that was granted higher up (only *deny policies* can).
- **A project has three identifiers:** project **ID** (globally unique, you choose it, never changes), project **number** (Google-assigned, used in service-agent emails) and display **name** (can change).
- **Billing** is linked per project to a *billing account* that lives outside the hierarchy and has its own IAM.
- Projects are usually **vended** by a platform/foundation team (often with Terraform), not created by hand — exactly what happened to you.

## Your goal

1. Make the `gcloud` CLI use **one named configuration per project**: `dev` and `staging`, each with that project's *platform-admin* identity and project set as default.
2. Explore where the projects sit in the hierarchy and record what you find in `~/week1/01-hierarchy.md`.

### Step 1 — Look around (your gcloud starts unauthenticated)

Run `gcloud auth list` and `gcloud config list`. Then open `~/week1/00-environment.md` to see your project IDs and key files.

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud auth list          # -> "No credentialed accounts."
gcloud config list        # -> the default configuration, no account/project
cat ~/week1/00-environment.md
echo $DEV_PROJECT $STAGING_PROJECT
```

A **configuration** is a named set of gcloud properties (account, project, region…). Using one per environment avoids the classic mistake of running a command against the wrong project.

</details>

### Step 2 — Create the `dev` configuration

Create a configuration called `dev`, authenticate it with the dev platform-admin key, and set the dev project as default.

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
# 1. create + activate a new, empty configuration
gcloud config configurations create dev

# 2. authenticate the dev bootstrap identity (sets core/account in the ACTIVE config)
gcloud auth activate-service-account --key-file=/root/.keys/dev-platform-admin.json

# 3. pin account + project for this configuration
gcloud config set account "$DEV_ADMIN_SA"
gcloud config set project "$DEV_PROJECT"

# 4. verify
gcloud config list
```

Your prompt should now show `[gcloud: dev | platform-admin-service-account]`.

</details>

### Step 3 — Create the `staging` configuration

Do the same for staging with the **staging** key and project.

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud config configurations create staging
gcloud auth activate-service-account --key-file=/root/.keys/staging-platform-admin.json
gcloud config set account "$STAGING_ADMIN_SA"
gcloud config set project "$STAGING_PROJECT"

gcloud config configurations list           # both configs, staging is ACTIVE
gcloud config configurations activate dev   # switch back whenever you need dev
```

Tip: you can also target a config for one command only: `gcloud --configuration=staging projects describe $STAGING_PROJECT`.

</details>

### Step 4 — Explore the hierarchy, billing and project boundaries

Find each project's **number** and **parent**, list its **ancestors**, check its **billing** link, and try to **create a new project**. Write what you observe (including errors!) in `~/week1/01-hierarchy.md`.

<details>
<summary>💡 Show step-by-step instructions</summary>

```bash
gcloud config configurations activate dev

# ID, number, parent, labels, lifecycle state
gcloud projects describe "$DEV_PROJECT"
gcloud projects describe "$DEV_PROJECT" --format="value(projectNumber,parent.type,parent.id)"

# Walk up the tree: project -> folder(s) -> organization
gcloud projects get-ancestors "$DEV_PROJECT"

# Billing: which billing account pays for this project?
gcloud billing projects describe "$DEV_PROJECT"
#   -> expect an error (API disabled / permission denied). Billing is managed by
#      billing-account admins OUTSIDE your project boundary. That is a finding - write it down.

# Can a platform admin of a project create new projects?
gcloud projects create "northwind-test-$RANDOM"
#   -> PERMISSION_DENIED: resourcemanager.projects.create is granted on a folder/org,
#      not on a project. Your identity only has power INSIDE its own project.

# Repeat the describe/ancestors commands for staging:
gcloud --configuration=staging projects describe "$STAGING_PROJECT" --format="value(projectNumber)"
gcloud --configuration=staging projects get-ancestors "$STAGING_PROJECT"
```

Now open the **Week 1 Notes (editor)** tab → `01-hierarchy.md` and replace every `_TODO_` (both project **numbers** must be in the table).

</details>

## Checklist

<instruqt-task id="t_configs"></instruqt-task>
