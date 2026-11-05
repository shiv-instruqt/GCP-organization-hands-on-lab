# ---------------------------------------------------------------- Chapter 1
resource "quiz" "quiz_hierarchy" {
  questions = [
    resource.single_choice_question.h_inherit,
    resource.single_choice_question.h_project_id,
    resource.multiple_choice_question.h_project_scope,
  ]
  show_hints = true
}

resource "single_choice_question" "h_inherit" {
  question = "Alice is granted roles/storage.objectViewer on the folder that contains the dev and staging projects. What can she read?"
  answer   = "Objects in every bucket in both projects (and any future project in that folder)"
  distractors = [
    "Nothing, until the role is also granted on each project",
    "Only objects in buckets created after the grant",
    "Only the folder's metadata",
  ]
  hints = ["IAM allow policies are inherited downwards through the hierarchy."]
}

resource "single_choice_question" "h_project_id" {
  question    = "Which project identifier is chosen by you, globally unique and can never be changed?"
  answer      = "Project ID"
  distractors = ["Project number", "Project display name", "Billing account ID"]
}

resource "multiple_choice_question" "h_project_scope" {
  question    = "Which of these are scoped to (enabled / measured / linked per) a PROJECT?"
  answer      = ["Enabled APIs", "Quotas", "Billing account link"]
  distractors = ["Organization policy administrators", "Google Workspace user accounts"]
  hints       = ["Think: what did you have to do separately for dev and staging?"]
}

# ---------------------------------------------------------------- Chapter 2
resource "quiz" "quiz_iam" {
  questions = [
    resource.single_choice_question.i_custom,
    resource.single_choice_question.i_scope,
    resource.single_choice_question.i_admin_vs_act,
  ]
  show_hints = true
}

resource "single_choice_question" "i_custom" {
  question = "When should you create a custom role?"
  answer   = "When no predefined role is narrow enough for the job"
  distractors = [
    "Always - predefined roles are insecure",
    "When you need to grant access across projects",
    "When you want the role to update automatically with new Google permissions",
  ]
  hints = ["Custom roles cost maintenance: Google won't add new permissions to them for you."]
}

resource "single_choice_question" "i_scope" {
  question = "dev-alice needs to upload to ONE bucket. Which grant is least privilege?"
  answer   = "appDeveloper (custom) on that bucket"
  distractors = [
    "roles/storage.objectAdmin on the project",
    "roles/editor on the project",
    "appDeveloper (custom) on the project",
  ]
}

resource "single_choice_question" "i_admin_vs_act" {
  question = "Your identity has roles/iam.serviceAccountAdmin on the project. Can it impersonate dev-alice?"
  answer   = "No - it also needs iam.serviceAccounts.getAccessToken (Service Account Token Creator)"
  distractors = [
    "Yes - admins can always act as the accounts they manage",
    "Yes - but only in the Cloud Console",
    "No - service accounts can never be impersonated",
  ]
}

# ---------------------------------------------------------------- Chapter 3
resource "quiz" "quiz_identity" {
  questions = [
    resource.single_choice_question.p_actas,
    resource.single_choice_question.p_keys,
    resource.multiple_choice_question.p_conditions,
  ]
  show_hints = true
}

resource "single_choice_question" "p_actas" {
  question = "Why grant roles/iam.serviceAccountUser to ci-deployer on app-runtime instead of on the staging project?"
  answer   = "On the project it could act as EVERY service account there, including more privileged ones"
  distractors = [
    "Project-level grants don't work for service accounts",
    "Cloud Run only accepts resource-level grants",
    "It is cheaper",
  ]
}

resource "single_choice_question" "p_keys" {
  question = "What is the recommended way for a GitHub Actions pipeline to authenticate as ci-deployer?"
  answer   = "Workload Identity Federation (short-lived tokens, no keys)"
  distractors = [
    "A JSON key stored as a GitHub secret",
    "A human user's OAuth refresh token",
    "An API key",
  ]
}

resource "multiple_choice_question" "p_conditions" {
  question = "Which statements about IAM Conditions are true?"
  answer = [
    "A request.time condition makes access expire automatically",
    "Policies containing conditions use policy version 3",
  ]
  distractors = [
    "Conditions can be attached to roles/owner",
    "A condition can remove access granted on a parent folder",
  ]
  hints = ["Conditions only restrict the binding they are attached to."]
}

# ---------------------------------------------------------------- Chapter 4
resource "quiz" "quiz_boundaries" {
  questions = [
    resource.single_choice_question.b_orgpolicy,
    resource.single_choice_question.b_boundary,
  ]
  show_hints = true
}

resource "single_choice_question" "b_orgpolicy" {
  question = "constraints/iam.disableServiceAccountKeyCreation is enforced on the organization. A project Owner runs 'gcloud iam service-accounts keys create'. What happens?"
  answer   = "It fails - org policies apply regardless of IAM roles"
  distractors = [
    "It succeeds because Owner has iam.serviceAccountKeys.create",
    "It succeeds but the key expires after 1 hour",
    "It succeeds only for service accounts created before the policy",
  ]
}

resource "single_choice_question" "b_boundary" {
  question = "ci-deployer lives in staging. What decides whether it can read gs://<dev>-app-data?"
  answer   = "The IAM policies on the bucket and its ancestors (dev project, folder, org)"
  distractors = [
    "The IAM policy of the staging project",
    "Whether ci-deployer has a key",
    "The staging project's org policies",
  ]
}

# ---------------------------------------------------------------- Final
resource "quiz" "quiz_final" {
  questions = [
    resource.single_choice_question.f_denied,
    resource.single_choice_question.f_broad,
    resource.text_answer_question.f_permission,
  ]
  show_hints = true
}

resource "single_choice_question" "f_denied" {
  question = "A developer gets 403 'does not have storage.objects.list access'. What is the best FIRST step?"
  answer   = "Run Policy Troubleshooter for that principal, permission and resource"
  distractors = [
    "Grant roles/editor and see if it goes away",
    "Grant roles/storage.admin on the project",
    "Create a service-account key for the developer",
  ]
}

resource "single_choice_question" "f_broad" {
  question = "Granting roles/storage.admin fixed the drill. Why is it still the wrong fix?"
  answer   = "It also allows deleting data and changing the bucket's IAM policy"
  distractors = [
    "It does not include storage.objects.list",
    "It expires after 24 hours",
    "Predefined roles cannot be granted on buckets",
  ]
}

resource "text_answer_question" "f_permission" {
  question = "Which single permission did you remove (and later restore) in the failure drill?"
  answer   = "storage.objects.list"
  hints    = ["It's the permission needed to list the objects in a bucket."]
}
