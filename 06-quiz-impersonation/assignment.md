---
slug: quiz-impersonation
type: quiz
title: "Quiz: managing vs acting as a service account"
teaser: "Admin is not the same as impersonation."
answers:
- "No - it also needs iam.serviceAccounts.getAccessToken (Service Account Token Creator)"
- "Yes - admins can always act as the accounts they manage"
- "Yes - but only in the Cloud Console"
- "No - service accounts can never be impersonated"
solution:
- 0
difficulty: intermediate
timelimit: 300
---

Your identity has roles/iam.serviceAccountAdmin on the project. Can it impersonate dev-alice?
