#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

EXPIRY=$(date -u -d "@$(( $(date +%s) + 7*24*3600 ))" +%Y-%m-%dT%H:%M:%SZ)
B=$(project_bindings gstg "$STAGING_PROJECT" "serviceAccount:$DEV_ALICE")
case "$CHECK" in
  conditional_binding|expiry_window)
    gstg projects add-iam-policy-binding "$STAGING_PROJECT" --member="serviceAccount:$DEV_ALICE" \
      --role=roles/storage.objectViewer \
      --condition="expression=request.time < timestamp('$EXPIRY'),title=week1-temporary-access,description=auto-solved" >/dev/null ;;
  no_unconditional)
    for r in $(awk -F'\t' '$3==""{print $1}' <<< "$B"); do
      gstg projects remove-iam-policy-binding "$STAGING_PROJECT" --member="serviceAccount:$DEV_ALICE" --role="$r" --condition=None >/dev/null
    done ;;
esac
exit 0
