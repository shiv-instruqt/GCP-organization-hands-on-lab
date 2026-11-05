#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

case "$CHECK" in
  dev_apis)     gdev services enable iamcredentials.googleapis.com policytroubleshooter.googleapis.com orgpolicy.googleapis.com ;;
  staging_apis) gstg services enable iamcredentials.googleapis.com artifactregistry.googleapis.com run.googleapis.com orgpolicy.googleapis.com ;;
  api_notes)
    cat > "$W1/02-api-enablement.md" <<NOTES
# 02 — API enablement notes (auto-solved)

| API | Project | Why it is needed | Enabled by (identity) | Command |
|-----|---------|------------------|-----------------------|---------|
| iamcredentials.googleapis.com | dev | Impersonate dev-alice | $DEV_ADMIN_SA | gcloud services enable iamcredentials.googleapis.com |
| policytroubleshooter.googleapis.com | dev | Failure drill | $DEV_ADMIN_SA | gcloud services enable policytroubleshooter.googleapis.com |
| orgpolicy.googleapis.com | dev | Read effective org policies | $DEV_ADMIN_SA | gcloud services enable orgpolicy.googleapis.com |
| iamcredentials.googleapis.com | staging | Impersonate ci-deployer | $STAGING_ADMIN_SA | gcloud services enable iamcredentials.googleapis.com |
| artifactregistry.googleapis.com | staging | Pipeline pushes images | $STAGING_ADMIN_SA | gcloud services enable artifactregistry.googleapis.com |
| run.googleapis.com | staging | Pipeline deploys Cloud Run | $STAGING_ADMIN_SA | gcloud services enable run.googleapis.com |
| orgpolicy.googleapis.com | staging | Read effective org policies | $STAGING_ADMIN_SA | gcloud services enable orgpolicy.googleapis.com |

## Already enabled
cloudresourcemanager, serviceusage, iam, storage - needed by the platform team to vend the project.
NOTES
    ;;
esac
exit 0
