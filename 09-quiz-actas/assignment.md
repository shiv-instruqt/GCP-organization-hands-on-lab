---
slug: quiz-actas
type: quiz
title: "Quiz: scoping actAs"
teaser: "Why resource-level beats project-level."
answers:
- "Project-level grants don't work for service accounts"
- "Cloud Run only accepts resource-level grants"
- "It is cheaper"
- "On the project it could act as EVERY service account there, including more privileged ones"
solution:
- 3
difficulty: intermediate
timelimit: 300
---

Why grant roles/iam.serviceAccountUser to ci-deployer on app-runtime instead of on the staging project?
