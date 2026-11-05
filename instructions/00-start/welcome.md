# Week 1 — GCP organization, projects and identity

**Goal:** understand Google Cloud's resource hierarchy and workload-identity model, and build a small, secure **multi-project foundation** — by hand, from fresh projects.

## The scenario

You just joined the platform team at **Northwind Payments** (a fictional company). The cloud foundation team has *vended* two brand-new, empty projects for a new service:

| Project | Purpose |
|---------|---------|
| **dev** | Developers build and test here |
| **staging** | Only the deployment pipeline deploys here |

Nothing is set up yet: most APIs are off, there are no workload identities, no custom roles and no IAM bindings. By the end of this lab you will have built — and documented — a least-privilege identity setup across both projects.

## What you will do

| Chapter | You will… |
|---------|-----------|
| 1. Hierarchy, projects & APIs | Explore org → folder → project, set up one CLI identity per project, enable APIs with `gcloud` |
| 2. IAM roles & developer identity | Compare predefined vs custom roles, create a least-privilege **developer** identity, use impersonation |
| 3. Pipeline identity & IAM Conditions | Create a **deployment pipeline** identity, grant `actAs` narrowly, give time-bound cross-project access |
| 4. Org policies, boundaries & quotas | Read effective org policies, prove project boundaries, look up quotas |
| 5. Failure drill | Remove a permission, diagnose the denial with **Policy Troubleshooter**, compare broad vs narrow fixes |
| 6. Deliverable | Identity map, API enablement notes, CLI command log and a least-privilege table |

## How this lab works

- **Try first, peek later.** Every step tells you *what* to achieve. The exact commands are hidden in collapsible blocks like this one:

<details>
<summary>💡 Show step-by-step instructions</summary>

You opened a hint! Inside these blocks you'll find the exact commands and an explanation of every flag. Use them when you are stuck — or afterwards to compare with what you did.

</details>

- **Checklists validate your work.** Each hands-on page ends with a task checklist. Click **Check** to validate — every item tells you exactly what is still missing.
- **Two extra help tabs:** *Hints & Cheat Sheet* (concepts + command reference) and *Troubleshooting* (common errors). They stay out of your way until you open them.
- **Your notes are the deliverable.** The *Week 1 Notes (editor)* tab opens `~/week1`. Templates are already there — replace every `_TODO_` as you go.
- **Every `gcloud` command is logged automatically** to `~/week1/commands.log`, together with *which identity* ran it and whether it succeeded. Your prompt always shows the active identity:

```text
[gcloud: dev | platform-admin-service-account] ~/week1 $
```

## Your identities in this lab

| Where | Identity | Can do |
|-------|----------|--------|
| GCP Console (tab *Console Login*) | `learner` user | **Read-only** (Viewer + Security Reviewer) — look, don't touch |
| Terminal (`gcloud`) | `platform-admin` service account (one per project) | Bootstrap APIs, service accounts, custom roles and IAM — but **not** Owner/Editor |

> [!NOTE]
> In a real company you would log in with your own user account and impersonate a platform-admin service account. Here a key file stands in for that bootstrap step — and you will see later why workload identities should **not** use keys.

> [!IMPORTANT]
> IAM changes are **eventually consistent**. After granting or removing access, wait 30–90 seconds before testing. If a check fails right after a change, wait a moment and click **Check** again.

When you're ready, go to **Chapter 1**.
