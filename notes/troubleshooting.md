# Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `You do not currently have an active account selected` | Active configuration has no account | `gcloud config configurations activate dev` (or `staging`) — or redo page 1.1 |
| Prompt shows `<not-authenticated>` | Same as above | Check `gcloud config list` |
| Command ran against the **wrong project** | Wrong configuration active | Look at the prompt; use `--configuration=…` for one-offs |
| `... API has not been used in project ... or it is disabled` / `SERVICE_DISABLED` | API not enabled in the **quota project** (the caller's project) | `gcloud services enable <api>` in that project |
| `Permission 'iam.serviceAccounts.getAccessToken' denied` | Missing Token Creator on the SA, **or** `iamcredentials.googleapis.com` not enabled, **or** propagation | Grant `roles/iam.serviceAccountTokenCreator` on the SA, enable the API, wait 60 s |
| Grant done but still `403` | IAM is eventually consistent | Wait 1–2 min (custom-role edits: up to ~7 min) and retry |
| `does not have storage.objects.delete access` when uploading | Overwriting an existing object needs `delete` | Upload under a new name — or that's the point of the lesson! |
| `--condition` errors / prompts for a condition | Policy already has conditional bindings | Add `--condition=None` for unconditional grants |
| `INVALID_ARGUMENT` on a condition | CEL syntax / quotes | Use `timestamp('2026-12-31T00:00:00Z')` with single quotes inside the double-quoted flag |
| `PERMISSION_DENIED` on `projects create`, `billing`, `org-policies reset` | Expected — those need folder/org/billing-account roles | Write down *why* in your notes |
| `troubleshoot-policy` returns `UNKNOWN_INFO` | Caller can't read every policy involved | Run it as the admin of the project that owns the resource |
| Task check fails right after you fixed something | Propagation delay | Wait 30–60 s and click **Check** again |

## Reset a configuration

```bash
gcloud config configurations activate default
gcloud config configurations delete dev      # then recreate it (page 1.1)
```

## Where is everything?

- Your notes: `~/week1` (editor tab *Week 1 Notes*)
- Automatic command log: `~/week1/commands.log`
- Project IDs & identities: `~/week1/00-environment.md`
- Bootstrap keys: `/root/.keys/`
