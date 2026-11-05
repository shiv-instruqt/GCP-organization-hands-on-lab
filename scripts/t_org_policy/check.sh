#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

case "$CHECK" in
  read_policies)
    grep -F "| exit=0 |" "$LOG" 2>/dev/null | grep -Eq "gcloud .*org-policies (list|describe)" \
      || fail "No successful 'gcloud org-policies list/describe' in commands.log." ;;
  boundary_tested)
    grep -F "| acting-as=$CI_DEPLOYER |" "$LOG" 2>/dev/null | grep -E '\| exit=[1-9][0-9]* \|' \
      | grep -Eq "DEV_BUCKET|$DEV_BUCKET" \
      || fail "No denied attempt by ci-deployer to read gs://$DEV_BUCKET in commands.log." ;;
  notes)
    f="$W1/04-org-policy-quotas.md"
    [ -f "$f" ] || fail "04-org-policy-quotas.md not found."
    grep -Eq "(iam|gcp|storage|compute|run|sql|essentialcontacts|resourcemanager)\.[a-zA-Z]{4,}" "$f" \
      || fail "Name at least one constraint (e.g. iam.disableServiceAccountKeyCreation) in 04-org-policy-quotas.md."
    no_todo "$f" || fail "04-org-policy-quotas.md still contains _TODO_ placeholders." ;;
  *) fail "Unknown check '$CHECK'" ;;
esac
exit 0
