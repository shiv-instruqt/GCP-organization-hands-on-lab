# -----------------------------------------------------------------------------
# Sandbox: two "freshly vended" GCP projects + one Cloud CLI workstation
#
#   dev      -> where the developer identity (dev-alice) works
#   staging  -> where the deployment pipeline identity (ci-deployer) deploys
#
# The learner's CLI identity in each project is the "platform-admin" service
# account. It is deliberately NOT owner/editor: it only has the admin roles a
# platform team needs to bootstrap identities, APIs and IAM.
#
# The console user "learner" is read-only (viewer + security reviewer) so all
# changes go through the CLI identity -> clean "who did what" story.
# -----------------------------------------------------------------------------

local "region" {
  value = "us-central1"
}

# APIs the projects are allowed to use. The bootstrap script DISABLES the
# learner-enabled ones again so the learner has to enable them with gcloud.
local "allowed_apis" {
  value = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "storage.googleapis.com",
    "policytroubleshooter.googleapis.com",
    "orgpolicy.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
}

local "platform_admin_roles" {
  value = [
    "roles/browser",                         # see project + ancestors (hierarchy)
    "roles/serviceusage.serviceUsageAdmin",  # enable/disable APIs, read quotas
    "roles/iam.serviceAccountAdmin",         # create SAs, set SA-level IAM (impersonation)
    "roles/iam.roleAdmin",                   # create/update custom roles
    "roles/resourcemanager.projectIamAdmin", # grant project-level roles + IAM Conditions
    "roles/iam.securityReviewer",            # read IAM everywhere (Policy Troubleshooter)
    "roles/orgpolicy.policyViewer",          # read effective org policies
    "roles/storage.admin",                   # create the test bucket + bucket-level IAM
  ]
}

local "console_user_roles" {
  value = [
    "roles/viewer",
    "roles/iam.securityReviewer",
  ]
}

resource "google_project" "northwind-dev" {
  regions  = [local.region]
  services = local.allowed_apis

  labels = {
    env    = "dev"
    course = "gcp-week1-identity"
  }

  user "learner" {
    roles = local.console_user_roles
  }

  service_account "platform-admin" {
    roles = local.platform_admin_roles
  }
}

resource "google_project" "northwind-staging" {
  regions  = [local.region]
  services = local.allowed_apis

  labels = {
    env    = "staging"
    course = "gcp-week1-identity"
  }

  user "learner" {
    roles = local.console_user_roles
  }

  service_account "platform-admin" {
    roles = local.platform_admin_roles
  }
}

# Service-account keys for the learner's bootstrap identity (one per project).
resource "template" "dev_admin_key" {
  source      = resource.google_project.northwind-dev.service_account.0.key
  destination = "${data("keys")}/dev-platform-admin.json"
}

resource "template" "staging_admin_key" {
  source      = resource.google_project.northwind-staging.service_account.0.key
  destination = "${data("keys")}/staging-platform-admin.json"
}

resource "container" "cloud_cli" {
  image {
    name = "gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine"
  }

  command = ["tail", "-f", "/dev/null"]

  environment = {
    DEV_PROJECT      = resource.google_project.northwind-dev.project_id
    STAGING_PROJECT  = resource.google_project.northwind-staging.project_id
    DEV_ADMIN_SA     = resource.google_project.northwind-dev.service_account.0.email
    STAGING_ADMIN_SA = resource.google_project.northwind-staging.service_account.0.email
    LAB_REGION       = local.region
  }

  volume {
    source      = resource.template.dev_admin_key.destination
    destination = "/root/.keys/dev-platform-admin.json"
  }

  volume {
    source      = resource.template.staging_admin_key.destination
    destination = "/root/.keys/staging-platform-admin.json"
  }

  resources {
    cpu    = 1000
    memory = 1024
  }
}

# One-time bootstrap: checker credentials, "fresh" APIs, notes templates,
# prompt that shows the active identity, and the automatic command log.
resource "exec" "bootstrap" {
  target  = resource.container.cloud_cli
  script  = "scripts/setup/bootstrap.sh"
  timeout = "600s"

  environment = {
    DEV_PROJECT      = resource.google_project.northwind-dev.project_id
    STAGING_PROJECT  = resource.google_project.northwind-staging.project_id
    DEV_ADMIN_SA     = resource.google_project.northwind-dev.service_account.0.email
    STAGING_ADMIN_SA = resource.google_project.northwind-staging.service_account.0.email
    LAB_REGION       = local.region
  }
}
