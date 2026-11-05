#!/bin/bash
# shellcheck disable=SC1091
source /opt/lab/lib.sh 2>/dev/null || { echo "The lab environment is still being prepared - wait a minute and click Check again."; exit 1; }

EXPECTED="storage.buckets.get storage.objects.create storage.objects.get storage.objects.list"
BREAK_RE='iam roles update.*appDeveloper.*remove-permissions[= ]+["'"'"']?storage\.objects\.list'
case "$CHECK" in
  broke_it)
    grep -F "| exit=0 |" "$LOG" 2>/dev/null | grep -Eq "$BREAK_RE" \
      || fail "No successful '--remove-permissions=storage.objects.list' on appDeveloper in commands.log." ;;
  saw_denial)
    n=$(grep -nE "$BREAK_RE" "$LOG" 2>/dev/null | grep -F "| exit=0 |" | tail -1 | cut -d: -f1)
    [ -n "$n" ] || fail "Remove the permission first (step 1)."
    tail -n +"$((n+1))" "$LOG" | grep -F "| acting-as=$DEV_ALICE |" | grep -Eq '\| exit=[1-9][0-9]* \|' \
      || fail "No denied command as dev-alice AFTER removing the permission. Wait for propagation and retry the list." ;;
  troubleshooter_saved)
    f="$W1/05-troubleshooter.txt"
    [ -s "$f" ] || fail "~/week1/05-troubleshooter.txt is missing or empty."
    grep -Eq "CANNOT_ACCESS|NOT_GRANTED" "$f" || fail "05-troubleshooter.txt does not show a denied result (CANNOT_ACCESS). Capture it while access is denied." ;;
  narrow_fix)
    have=$(custom_role_perms gdev appDeveloper | sort | xargs)
    [ "$have" = "$EXPECTED" ] || fail "appDeveloper has [$have] - expected exactly [$EXPECTED]." ;;
  broad_removed)
    bad=$( { bucket_roles "$DEV_BUCKET" "serviceAccount:$DEV_ALICE"; project_roles gdev "$DEV_PROJECT" "serviceAccount:$DEV_ALICE"; } \
           | grep -Ex "roles/(storage\.admin|storage\.objectAdmin|editor|owner)" | xargs)
    [ -z "$bad" ] || fail "dev-alice still holds broad role(s): $bad" ;;
  notes)
    f="$W1/05-failure-drill.md"
    [ -f "$f" ] || fail "05-failure-drill.md not found."
    grep -q "storage.admin" "$f" || fail "Mention roles/storage.admin (the broad option) in 05-failure-drill.md."
    grep -q "appDeveloper" "$f"  || fail "Mention appDeveloper (the narrow option) in 05-failure-drill.md."
    no_todo "$f" || fail "05-failure-drill.md still contains _TODO_ placeholders." ;;
  *) fail "Unknown check '$CHECK'" ;;
esac
exit 0
