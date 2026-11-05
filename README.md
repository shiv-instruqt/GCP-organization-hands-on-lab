# Week 1 — GCP organization, projects and identity (Instruqt Lab)

An Instruqt **Labs 2.0** lab (HCL) in which learners build a small, secure **multi-project foundation** on Google Cloud by hand, starting from two fresh projects.

**Learners will:** explore the resource hierarchy → set up one `gcloud` identity per project → enable APIs with `gcloud` → create least-privilege identities for a **developer** (`dev-alice`) and a **deployment pipeline** (`ci-deployer` + `app-runtime`) → use **impersonation** and **IAM Conditions** → read **org policies** and **quotas** → run a **failure drill** with **Policy Troubleshooter** → hand in an **identity map, API notes, CLI command log and least-privilege table**.

## Lab design at a glance

| Item | Choice |
|------|--------|
| Format | Labs 2.0 (HCL). Validated with `instruqt lab validate` (CLI build 2442) |
| Sandbox | 2 × `google_project` (`northwind-dev`, `northwind-staging`) in `us-central1` + 1 `google-cloud-cli:alpine` container |
| Learner CLI identity | `platform-admin` service account per project, **not** Owner/Editor (Browser, Service Usage Admin, SA Admin, Role Admin, Project IAM Admin, Security Reviewer, Org Policy Viewer, Storage Admin) |
| Learner console identity | `learner` user, read-only (Viewer + Security Reviewer) |
| "Fresh" projects | Bootstrap **disables** `iamcredentials`, `policytroubleshooter`, `orgpolicy`, `artifactregistry`, `run` so learners must enable them |
| Hidden instructions | Every step's commands sit in collapsible `<details>` blocks + two hidden-until-opened tabs (*Hints & Cheat Sheet*, *Troubleshooting*) |
| Checklists | 9 tasks / 38 conditions, each with a specific failure message and a solve (skip) script |
| Quizzes | 5 knowledge checks (14 questions) |
| Audit trail | Every `gcloud` command is auto-logged to `~/week1/commands.log` with the config, account, **acting-as** identity and exit code; the prompt always shows the active identity |
| Time limit | 3 h (+30 min extension), idle timeout 30 min |

## Chapters

| # | Page | Task (checklist) |
|---|------|------------------|
| 0 | Welcome & scenario | — |
| 1.1 | Explore the hierarchy & set up CLI identities | `t_configs` (3) |
| 1.2 | Enable APIs with gcloud | `t_apis` (3) + quiz |
| 2.1 | Predefined vs custom roles — developer identity | `t_developer` (5) |
| 2.2 | Act as the developer with impersonation | `t_impersonate_dev` (4) + quiz |
| 3.1 | Least-privilege pipeline identity | `t_pipeline` (7) |
| 3.2 | Time-bound cross-project access (IAM Conditions) | `t_conditions` (3) + quiz |
| 4 | Org policies, boundaries & quotas | `t_org_policy` (3) + quiz |
| 5 | Failure drill (break → Troubleshooter → broad vs narrow fix) | `t_drill` (6) |
| 6 | End-of-week deliverable | `t_deliverable` (4) + final quiz |

## Repository layout

```text
main.hcl                 lab resource: chapters, pages, settings
sandbox.hcl              GCP projects, CLI container, key templates, bootstrap exec
tabs.hcl                 terminals, editor, cloud credentials, console link, notes
layouts.hcl              workbench + reading layouts
pages.hcl                page -> markdown + activities
tasks.hcl                9 tasks; each condition runs scripts/<task>/check.sh|solve.sh with CHECK=<id>
quizzes.hcl              quizzes and questions
instructions/            learner-facing markdown (one folder per chapter)
notes/                   cheat sheet + troubleshooting tabs
scripts/setup/bootstrap.sh   one-time setup inside the container
scripts/t_*/check.sh     validation (exit 0 = pass)
scripts/t_*/solve.sh     reference solution used when a learner skips
```

## Import into Instruqt

1. Push this folder to an **empty** GitHub repository (files at the repo root).
2. Make sure the Instruqt GitHub integration is installed and has access to the repo (*Settings → Version Control*).
3. In Instruqt Labs: **Import lab** → select the repo → lab directory `/` → fill in name/details.
4. Check that your team's **cloud services & regions** settings allow GCP projects with the APIs in `sandbox.hcl` → `local "allowed_apis"` and region `us-central1`.

Validate locally before every push:

```bash
instruqt lab validate .
instruqt lab format .
```

## First-run test plan (do this once as an author)

These points depend on platform behavior that can't be verified offline — please check them on the first play-through:

- [ ] **Collapsible hints:** `<details><summary>` blocks render collapsed in the Labs 2.0 instructions panel (works in classic Tracks). If not, move the hidden steps to the *Hints & Cheat Sheet* note tab.
- [ ] **Bootstrap:** after start, `~/week1` contains the note templates and the prompt shows `[gcloud: default | <not-authenticated>]`. Logs: `instruqt lab logs`.
- [ ] **Fresh APIs:** `gcloud services list --enabled` in each project does **not** show the 5 learner-enabled APIs (bootstrap disables them; it retries for ~90 s while IAM propagates).
- [ ] **Roles accepted:** the sandbox accepts every role in `platform_admin_roles` (especially `roles/orgpolicy.policyViewer` and `roles/iam.roleAdmin`).
- [ ] **Cross-project binding:** granting `dev-alice@<dev>` a role in staging is allowed (no `iam.allowedPolicyMemberDomains` restriction blocking service accounts).
- [ ] **Skip / solve:** skipping each task passes all its checks (good smoke test of the whole lab).

## Classic Track (v1) version — same folder

The same lab also exists as a classic **Instruqt Track**. Both formats live side by side in this folder and ignore each other's files (`instruqt track validate` and `instruqt lab validate` both pass).

| Track file | Purpose |
|------------|---------|
| `track.yml` | Track metadata (slug `gcp-week1-organization-projects-identity`, owner `instruqt`, 3 h limit, skipping enabled) |
| `config.yml` | `cloud-client` container + `gcp_projects` `northwinddev` / `northwindstaging` (us-central1, same APIs; roles apply to the project's user **and** service account) |
| `track_scripts/setup-cloud-client` | Same bootstrap as the lab: key files from the `INSTRUQT_GCP_PROJECT_*` variables, checker credentials, "fresh" APIs, note templates, identity prompt, command log, help files in `~/week1/help/` |
| `01-…` to `09-…` | 9 hands-on challenges (`assignment.md` + `check-cloud-client` + `solve-cloud-client`) — no quizzes, no reading-only pages |

Challenges (all hands-on): hierarchy & CLI identities → enable APIs → developer identity → impersonation + IAM inheritance → pipeline identity → IAM Conditions → org policies/boundaries/quotas → failure drill → deliverable. Background explanations are collapsed (📖 Background) and optional.

Differences from the Labs 2.0 version:
- Each challenge has one **Check** button; the check script runs every checklist item and reports the first one that fails (`FAIL: …`). The checklist is listed at the bottom of each assignment.
- Help (cheat sheet + troubleshooting) is in `~/week1/help/` (open it in the *Notes* tab) instead of note tabs.
- Tracks have one `roles` list per project that applies to both the console user and the service account. `roles/orgpolicy.policyViewer` was left out (it may not be grantable at project level, which would break provisioning); Security Reviewer covers reading org policies. Staging has no `roles/storage.admin` because nothing there needs it.

### Get the track into Instruqt

**Option A — Instruqt CLI (quickest):**
```bash
instruqt auth login
instruqt track validate
instruqt track push      # creates the track and writes its id into track.yml
```

**Option B — GitHub version control:** Instruqt can only connect a track to an **empty** repository.
1. In Instruqt, create a track (any title) → *Version control* → **Connect to a remote repository** → pick a new, empty repo. Instruqt pushes its own `track.yml`/`config.yml`.
2. Copy these track files into that repo (overwrite), but **keep the `id:` (and `slug:`/`owner:`) lines Instruqt wrote** in `track.yml`.
3. Commit and push to `main` — Instruqt syncs the track.

Because this folder also contains the Labs 2.0 files, use a separate empty repo for Option B (or Option A from this folder).

## Known platform gotchas (found on the first run, 5 Nov 2026)

- **Don't use list-valued `local` blocks** for `services` or `roles` in `google_project`. They pass `instruqt lab validate` but reach the provisioner empty: logs show `services not requested`, `role_count: 0`, then `SetGoogleProjectOrgPolicy constraints/gcp.restrictServiceUsage allowed_value_count: 0 → Error 400`, and the lab fails. Lists are now inline in `sandbox.hcl`.
- A `service_account "platform-admin"` block becomes `platform-admin-service-account@<project>.iam.gserviceaccount.com` (Instruqt appends `-service-account`; the 30-character account-ID limit means a longer label would break). Scripts always use `.service_account.0.email`, so nothing is hard-coded.

## Notes for maintainers

- Check scripts use a **private gcloud config** (`/opt/lab/gcloud`) so learners can't break validation by changing their own configuration.
- Helpers live in `/opt/lab/lib.sh` (written by the bootstrap): `gdev`, `gstg`, `project_roles`, `sa_roles`, `bucket_roles`, `custom_role_perms`, `log_ok_as`, `log_denied_as`, `no_todo`.
- Note-file checks only require that `_TODO_` placeholders are gone plus a few key facts (project numbers, emails, role names) — they don't grade writing quality.
- Command-log checks (`impersonated_ok`, `boundary_tested`, `saw_denial`…) rely on the learner using the lab terminals.
