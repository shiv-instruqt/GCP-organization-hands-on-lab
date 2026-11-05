resource "lab" "gcp_week1_identity" {
  title       = "Week 1 — GCP Organization, Projects and Identity"
  description = "Build a small, secure multi-project foundation on Google Cloud from fresh projects: resource hierarchy, APIs, IAM roles (predefined vs custom), service accounts, impersonation, IAM Conditions, org policies, quotas and a real access-denied failure drill with Policy Troubleshooter."

  settings {
    timelimit {
      duration   = "3h"
      extend     = "30m"
      show_timer = true
    }

    idle {
      enabled      = true
      timeout      = "30m"
      show_warning = true
    }
  }

  layout = resource.layout.workbench

  content {
    title = "Week 1 Lab"

    chapter "start" {
      title = "Start here"

      page "welcome" {
        reference = resource.page.welcome
        layout    = resource.layout.reading
      }
    }

    chapter "hierarchy" {
      title = "1. Hierarchy, projects & APIs"

      page "projects" {
        reference = resource.page.projects
      }

      page "apis" {
        reference = resource.page.apis
      }
    }

    chapter "iam" {
      title = "2. IAM roles & the developer identity"

      page "iam_roles" {
        reference = resource.page.iam_roles
      }

      page "impersonate_dev" {
        reference = resource.page.impersonate_dev
      }
    }

    chapter "pipeline" {
      title = "3. Pipeline identity & IAM Conditions"

      page "pipeline_sa" {
        reference = resource.page.pipeline_sa
      }

      page "conditions" {
        reference = resource.page.conditions
      }
    }

    chapter "boundaries" {
      title = "4. Org policies, boundaries & quotas"

      page "org_policy" {
        reference = resource.page.org_policy
      }
    }

    chapter "drill" {
      title = "5. Failure drill"

      page "failure_drill" {
        reference = resource.page.failure_drill
      }
    }

    chapter "deliverable" {
      title = "6. End-of-week deliverable"

      page "deliverable" {
        reference = resource.page.deliverable
      }
    }
  }
}
