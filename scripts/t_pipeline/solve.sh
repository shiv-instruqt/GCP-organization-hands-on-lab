#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

ALLOWED="roles/artifactregistry.writer roles/run.developer"
case "$CHECK" in
  sas_created)
    sa_exists gstg "$CI_DEPLOYER" || gstg iam service-accounts create ci-deployer --display-name="CI/CD deployer"
    sa_exists gstg "$APP_RUNTIME" || gstg iam service-accounts create app-runtime --display-name="App runtime" ;;
  deployer_roles)
    for r in $ALLOWED; do
      gstg projects add-iam-policy-binding "$STAGING_PROJECT" --member="serviceAccount:$CI_DEPLOYER" --role="$r" --condition=None >/dev/null
    done ;;
  no_broad_roles)
    for r in $(project_roles gstg "$STAGING_PROJECT" "serviceAccount:$CI_DEPLOYER"); do
      case " $ALLOWED " in *" $r "*) ;; *)
        gstg projects remove-iam-policy-binding "$STAGING_PROJECT" --member="serviceAccount:$CI_DEPLOYER" --role="$r" --all >/dev/null ;;
      esac
    done ;;
  actas_scoped)
    gstg iam service-accounts add-iam-policy-binding "$APP_RUNTIME" \
      --member="serviceAccount:$CI_DEPLOYER" --role=roles/iam.serviceAccountUser >/dev/null ;;
  ci_impersonation)
    gstg iam service-accounts add-iam-policy-binding "$CI_DEPLOYER" \
      --member="serviceAccount:$STAGING_ADMIN_SA" --role=roles/iam.serviceAccountTokenCreator >/dev/null ;;
  no_keys)
    for k in $(gstg iam service-accounts keys list --iam-account="$CI_DEPLOYER" --managed-by=user --format="value(name.basename())"); do
      gstg iam service-accounts keys delete "$k" --iam-account="$CI_DEPLOYER" --quiet
    done ;;
  tested)
    log_note 0 "$CI_DEPLOYER" "gcloud run services list --region=$LAB_REGION --impersonate-service-account=$CI_DEPLOYER   # (auto-solved)" ;;
esac
exit 0
