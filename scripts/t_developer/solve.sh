#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

PERMS="storage.buckets.get,storage.objects.get,storage.objects.list,storage.objects.create"
case "$CHECK" in
  sa_created)
    sa_exists gdev "$DEV_ALICE" || gdev iam service-accounts create dev-alice --display-name="Developer: Alice" ;;
  bucket_created)
    gdev storage buckets describe "gs://$DEV_BUCKET" >/dev/null 2>&1 || \
      gdev storage buckets create "gs://$DEV_BUCKET" --location="$LAB_REGION" --uniform-bucket-level-access ;;
  custom_role)
    if gdev iam roles describe appDeveloper --project="$DEV_PROJECT" >/dev/null 2>&1; then
      gdev iam roles undelete appDeveloper --project="$DEV_PROJECT" >/dev/null 2>&1
      gdev iam roles update appDeveloper --project="$DEV_PROJECT" --permissions="$PERMS"
    else
      gdev iam roles create appDeveloper --project="$DEV_PROJECT" --title="App Developer (dev data)" --permissions="$PERMS" --stage=GA
    fi ;;
  bucket_binding)
    gdev storage buckets add-iam-policy-binding "gs://$DEV_BUCKET" \
      --member="serviceAccount:$DEV_ALICE" --role="projects/$DEV_PROJECT/roles/appDeveloper" >/dev/null ;;
  no_project_roles)
    for r in $(project_roles gdev "$DEV_PROJECT" "serviceAccount:$DEV_ALICE"); do
      gdev projects remove-iam-policy-binding "$DEV_PROJECT" --member="serviceAccount:$DEV_ALICE" --role="$r" --all >/dev/null
    done ;;
esac
exit 0
