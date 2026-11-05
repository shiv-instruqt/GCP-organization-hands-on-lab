#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

case "$CHECK" in
  read_policies)
    log_note 0 "$DEV_ADMIN_SA" "gcloud org-policies describe iam.disableServiceAccountKeyCreation --project=$DEV_PROJECT --effective   # (auto-solved)" ;;
  boundary_tested)
    log_note 1 "$CI_DEPLOYER" "gcloud storage ls gs://$DEV_BUCKET --impersonate-service-account=$CI_DEPLOYER   # (auto-solved)" ;;
  notes)
    cat > "$W1/04-org-policy-quotas.md" <<NOTES
# 04 — Org policies, project boundaries & quotas (auto-solved)

## Effective org policies
$(gdev org-policies list --project="$DEV_PROJECT" 2>&1 | head -20)
- iam.disableServiceAccountKeyCreation: blocks SA keys -> use impersonation / WIF.
- gcp.resourceLocations: limits where resources may be created.

## Project boundary test
ci-deployer (staging) was denied storage.objects.list on gs://$DEV_BUCKET (dev): access is decided by the resource's IAM policy.

## Quota
run.googleapis.com - see consumerQuotaMetrics; raise via Quotas page / quota increase request.
NOTES
    ;;
esac
exit 0
