resource "page" "welcome" {
  title = "Welcome & scenario"
  file  = "instructions/00-start/welcome.md"
}

resource "page" "projects" {
  title = "Explore the hierarchy & set up your CLI identities"
  file  = "instructions/01-hierarchy/projects.md"

  activities = {
    t_configs = resource.task.t_configs
  }
}

resource "page" "apis" {
  title = "Enable the required APIs with gcloud"
  file  = "instructions/01-hierarchy/apis.md"

  activities = {
    t_apis         = resource.task.t_apis
    quiz_hierarchy = resource.quiz.quiz_hierarchy
  }
}

resource "page" "iam_roles" {
  title = "Predefined vs custom roles — the developer identity"
  file  = "instructions/02-iam/iam-roles.md"

  activities = {
    t_developer = resource.task.t_developer
  }
}

resource "page" "impersonate_dev" {
  title = "Act as the developer with impersonation"
  file  = "instructions/02-iam/impersonate-dev.md"

  activities = {
    t_impersonate_dev = resource.task.t_impersonate_dev
    quiz_iam          = resource.quiz.quiz_iam
  }
}

resource "page" "pipeline_sa" {
  title = "A least-privilege deployment pipeline identity"
  file  = "instructions/03-pipeline/pipeline-sa.md"

  activities = {
    t_pipeline = resource.task.t_pipeline
  }
}

resource "page" "conditions" {
  title = "Time-bound cross-project access with IAM Conditions"
  file  = "instructions/03-pipeline/conditions.md"

  activities = {
    t_conditions  = resource.task.t_conditions
    quiz_identity = resource.quiz.quiz_identity
  }
}

resource "page" "org_policy" {
  title = "Org policies, project boundaries & quotas"
  file  = "instructions/04-boundaries/org-policy.md"

  activities = {
    t_org_policy    = resource.task.t_org_policy
    quiz_boundaries = resource.quiz.quiz_boundaries
  }
}

resource "page" "failure_drill" {
  title = "Break it, diagnose it, fix it narrowly"
  file  = "instructions/05-drill/failure-drill.md"

  activities = {
    t_drill = resource.task.t_drill
  }
}

resource "page" "deliverable" {
  title = "Identity map & least-privilege table"
  file  = "instructions/06-deliverable/deliverable.md"

  activities = {
    t_deliverable = resource.task.t_deliverable
    quiz_final    = resource.quiz.quiz_final
  }
}
