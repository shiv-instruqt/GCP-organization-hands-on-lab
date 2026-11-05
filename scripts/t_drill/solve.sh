#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

PERMS="storage.buckets.get,storage.objects.get,storage.objects.list,storage.objects.create"
case "$CHECK" in
  broke_it)
    log_note 0 "$DEV_ADMIN_SA" "gcloud iam roles update appDeveloper --project=$DEV_PROJECT --remove-permissions=storage.objects.list   # (auto-solved)" ;;
  saw_denial)
    log_note 1 "$DEV_ALICE" "gcloud storage ls gs://$DEV_BUCKET --impersonate-service-account=$DEV_ALICE   # (auto-solved)" ;;
  troubleshooter_saved)
    [ -s "$W1/05-troubleshooter.txt" ] || printf 'overallAccessState: CANNOT_ACCESS\n# (auto-solved placeholder)\n' > "$W1/05-troubleshooter.txt" ;;
  narrow_fix)
    gdev iam roles update appDeveloper --project="$DEV_PROJECT" --permissions="$PERMS" >/dev/null ;;
  broad_removed)
    for r in roles/storage.admin roles/storage.objectAdmin roles/editor roles/owner; do
      gdev storage buckets remove-iam-policy-binding "gs://$DEV_BUCKET" --member="serviceAccount:$DEV_ALICE" --role="$r" >/dev/null 2>&1
      gdev projects remove-iam-policy-binding "$DEV_PROJECT" --member="serviceAccount:$DEV_ALICE" --role="$r" --all >/dev/null 2>&1
    done; true ;;
  notes)
    cat > "$W1/05-failure-drill.md" <<'NOTES'
# 05 — Failure drill (auto-solved)

Removed storage.objects.list from appDeveloper -> dev-alice got 403 on list.
Policy Troubleshooter: CANNOT_ACCESS, appDeveloper binding matched but permission not included.

| Option | Role / change | Risk |
|--------|---------------|------|
| Broad  | roles/storage.admin on the bucket | delete data, change bucket IAM |
| Narrow | add storage.objects.list back to appDeveloper | none beyond the need |

Kept the narrow fix.
NOTES
    ;;
esac
exit 0
