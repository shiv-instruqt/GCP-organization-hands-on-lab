# Each task = a checklist. Every condition calls the task's check.sh / solve.sh with CHECK=<condition id>.

resource "task" "t_configs" {
  description     = "Set up one gcloud configuration per project and record the hierarchy"
  success_message = "Both CLI identities are configured and the hierarchy is documented."

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "dev_config" {
    description = "gcloud configuration `dev` uses the dev platform-admin identity and the dev project"

    check {
      script          = "scripts/t_configs/check.sh"
      failure_message = "Configuration `dev` is missing, or its account/project is wrong. Run `gcloud config configurations describe dev`."

      config {
        environment = { CHECK = "dev_config" }
      }
    }

    solve {
      script = "scripts/t_configs/solve.sh"

      config {
        environment = { CHECK = "dev_config" }
      }
    }
  }

  condition "staging_config" {
    description = "gcloud configuration `staging` uses the staging platform-admin identity and the staging project"

    check {
      script          = "scripts/t_configs/check.sh"
      failure_message = "Configuration `staging` is missing, or its account/project is wrong. Run `gcloud config configurations describe staging`."

      config {
        environment = { CHECK = "staging_config" }
      }
    }

    solve {
      script = "scripts/t_configs/solve.sh"

      config {
        environment = { CHECK = "staging_config" }
      }
    }
  }

  condition "hierarchy_notes" {
    description = "`~/week1/01-hierarchy.md` has both project NUMBERS and no `_TODO_` left"

    check {
      script          = "scripts/t_configs/check.sh"
      failure_message = "Add both project numbers (gcloud projects describe ... --format='value(projectNumber)') and answer every _TODO_ in ~/week1/01-hierarchy.md."

      config {
        environment = { CHECK = "hierarchy_notes" }
      }
    }

    solve {
      script = "scripts/t_configs/solve.sh"

      config {
        environment = { CHECK = "hierarchy_notes" }
      }
    }
  }

}

resource "task" "t_apis" {
  description     = "Enable the required APIs and document who enabled them"
  success_message = "APIs enabled and documented - nice audit trail!"

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "dev_apis" {
    description = "dev: iamcredentials, policytroubleshooter and orgpolicy APIs are enabled"

    check {
      script          = "scripts/t_apis/check.sh"
      failure_message = "Some dev APIs are still disabled. Run: gcloud --configuration=dev services list --enabled"

      config {
        environment = { CHECK = "dev_apis" }
      }
    }

    solve {
      script = "scripts/t_apis/solve.sh"

      config {
        environment = { CHECK = "dev_apis" }
      }
    }
  }

  condition "staging_apis" {
    description = "staging: iamcredentials, artifactregistry, run and orgpolicy APIs are enabled"

    check {
      script          = "scripts/t_apis/check.sh"
      failure_message = "Some staging APIs are still disabled. Run: gcloud --configuration=staging services list --enabled"

      config {
        environment = { CHECK = "staging_apis" }
      }
    }

    solve {
      script = "scripts/t_apis/solve.sh"

      config {
        environment = { CHECK = "staging_apis" }
      }
    }
  }

  condition "api_notes" {
    description = "`~/week1/02-api-enablement.md` lists every API and the identity that enabled it"

    check {
      script          = "scripts/t_apis/check.sh"
      failure_message = "Complete ~/week1/02-api-enablement.md: one row per API, include the platform-admin email in 'Enabled by', and remove every _TODO_."

      config {
        environment = { CHECK = "api_notes" }
      }
    }

    solve {
      script = "scripts/t_apis/solve.sh"

      config {
        environment = { CHECK = "api_notes" }
      }
    }
  }

}

resource "task" "t_developer" {
  description     = "Create the least-privilege developer identity in dev"
  success_message = "dev-alice can do exactly what a developer needs - nothing more."

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "sa_created" {
    description = "Service account `dev-alice` exists in dev"

    check {
      script          = "scripts/t_developer/check.sh"
      failure_message = "Service account dev-alice not found in the dev project."

      config {
        environment = { CHECK = "sa_created" }
      }
    }

    solve {
      script = "scripts/t_developer/solve.sh"

      config {
        environment = { CHECK = "sa_created" }
      }
    }
  }

  condition "bucket_created" {
    description = "Bucket `<dev-project>-app-data` exists"

    check {
      script          = "scripts/t_developer/check.sh"
      failure_message = "Bucket gs://$DEV_BUCKET not found. Create it in us-central1 with uniform bucket-level access."

      config {
        environment = { CHECK = "bucket_created" }
      }
    }

    solve {
      script = "scripts/t_developer/solve.sh"

      config {
        environment = { CHECK = "bucket_created" }
      }
    }
  }

  condition "custom_role" {
    description = "Custom role `appDeveloper` has exactly: storage.buckets.get, storage.objects.get, storage.objects.list, storage.objects.create"

    check {
      script          = "scripts/t_developer/check.sh"
      failure_message = "Custom role appDeveloper is missing or its permissions are not exactly the 4 required ones."

      config {
        environment = { CHECK = "custom_role" }
      }
    }

    solve {
      script = "scripts/t_developer/solve.sh"

      config {
        environment = { CHECK = "custom_role" }
      }
    }
  }

  condition "bucket_binding" {
    description = "`dev-alice` holds `appDeveloper` on the bucket"

    check {
      script          = "scripts/t_developer/check.sh"
      failure_message = "dev-alice is not bound to projects/<dev>/roles/appDeveloper on the bucket."

      config {
        environment = { CHECK = "bucket_binding" }
      }
    }

    solve {
      script = "scripts/t_developer/solve.sh"

      config {
        environment = { CHECK = "bucket_binding" }
      }
    }
  }

  condition "no_project_roles" {
    description = "`dev-alice` has NO project-level roles in dev"

    check {
      script          = "scripts/t_developer/check.sh"
      failure_message = "dev-alice has a project-level role in dev. Remove it - grant at bucket scope only."

      config {
        environment = { CHECK = "no_project_roles" }
      }
    }

    solve {
      script = "scripts/t_developer/solve.sh"

      config {
        environment = { CHECK = "no_project_roles" }
      }
    }
  }

}

resource "task" "t_impersonate_dev" {
  description     = "Work as dev-alice through impersonation"
  success_message = "You used short-lived credentials instead of keys. That's the way!"

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "token_creator" {
    description = "dev platform-admin has Token Creator ON the dev-alice service account (not on the project)"

    check {
      script          = "scripts/t_impersonate_dev/check.sh"
      failure_message = "Grant roles/iam.serviceAccountTokenCreator to the dev platform-admin on the dev-alice service account - and not at project level."

      config {
        environment = { CHECK = "token_creator" }
      }
    }

    solve {
      script = "scripts/t_impersonate_dev/solve.sh"

      config {
        environment = { CHECK = "token_creator" }
      }
    }
  }

  condition "object_uploaded" {
    description = "`hello.txt` exists in the dev bucket"

    check {
      script          = "scripts/t_impersonate_dev/check.sh"
      failure_message = "gs://$DEV_BUCKET/hello.txt not found."

      config {
        environment = { CHECK = "object_uploaded" }
      }
    }

    solve {
      script = "scripts/t_impersonate_dev/solve.sh"

      config {
        environment = { CHECK = "object_uploaded" }
      }
    }
  }

  condition "impersonated_ok" {
    description = "A gcloud command succeeded while acting as dev-alice"

    check {
      script          = "scripts/t_impersonate_dev/check.sh"
      failure_message = "No successful command acting as dev-alice in ~/week1/commands.log. Use --impersonate-service-account=$DEV_ALICE."

      config {
        environment = { CHECK = "impersonated_ok" }
      }
    }

    solve {
      script = "scripts/t_impersonate_dev/solve.sh"

      config {
        environment = { CHECK = "impersonated_ok" }
      }
    }
  }

  condition "impersonated_denied" {
    description = "You observed at least one DENIED action as dev-alice"

    check {
      script          = "scripts/t_impersonate_dev/check.sh"
      failure_message = "Try something dev-alice may not do (e.g. delete hello.txt) with --impersonate-service-account=$DEV_ALICE."

      config {
        environment = { CHECK = "impersonated_denied" }
      }
    }

    solve {
      script = "scripts/t_impersonate_dev/solve.sh"

      config {
        environment = { CHECK = "impersonated_denied" }
      }
    }
  }

  condition "inherit_denied" {
    description = "As dev-alice, listing the `-reports` bucket was DENIED (no grant on it yet)"

    check {
      script          = "scripts/t_impersonate_dev/check.sh"
      failure_message = "Create gs://$DEV_PROJECT-reports and try to list it as dev-alice - it should be denied."

      config {
        environment = { CHECK = "inherit_denied" }
      }
    }

    solve {
      script = "scripts/t_impersonate_dev/solve.sh"

      config {
        environment = { CHECK = "inherit_denied" }
      }
    }
  }

  condition "inherit_allowed" {
    description = "After a PROJECT-level grant, dev-alice listed the `-reports` bucket successfully (inheritance)"

    check {
      script          = "scripts/t_impersonate_dev/check.sh"
      failure_message = "Grant dev-alice roles/storage.objectViewer on the dev project, wait ~60 s, then list gs://$DEV_PROJECT-reports as dev-alice."

      config {
        environment = { CHECK = "inherit_allowed" }
      }
    }

    solve {
      script = "scripts/t_impersonate_dev/solve.sh"

      config {
        environment = { CHECK = "inherit_allowed" }
      }
    }
  }

  condition "inherit_cleaned" {
    description = "The project-level grant was removed again - dev-alice has no project roles"

    check {
      script          = "scripts/t_impersonate_dev/check.sh"
      failure_message = "Remove dev-alice's project-level role(s) in dev again."

      config {
        environment = { CHECK = "inherit_cleaned" }
      }
    }

    solve {
      script = "scripts/t_impersonate_dev/solve.sh"

      config {
        environment = { CHECK = "inherit_cleaned" }
      }
    }
  }
}

resource "task" "t_pipeline" {
  description     = "Create the least-privilege deployment pipeline identity in staging"
  success_message = "Your pipeline can deploy - and nothing else."

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "sas_created" {
    description = "Service accounts `ci-deployer` and `app-runtime` exist in staging"

    check {
      script          = "scripts/t_pipeline/check.sh"
      failure_message = "ci-deployer and/or app-runtime not found in the staging project."

      config {
        environment = { CHECK = "sas_created" }
      }
    }

    solve {
      script = "scripts/t_pipeline/solve.sh"

      config {
        environment = { CHECK = "sas_created" }
      }
    }
  }

  condition "deployer_roles" {
    description = "`ci-deployer` has roles/run.developer and roles/artifactregistry.writer on the staging project"

    check {
      script          = "scripts/t_pipeline/check.sh"
      failure_message = "ci-deployer is missing roles/run.developer and/or roles/artifactregistry.writer at project level."

      config {
        environment = { CHECK = "deployer_roles" }
      }
    }

    solve {
      script = "scripts/t_pipeline/solve.sh"

      config {
        environment = { CHECK = "deployer_roles" }
      }
    }
  }

  condition "no_broad_roles" {
    description = "`ci-deployer` has NO broad project roles (owner, editor, run.admin, serviceAccountUser, tokenCreator...)"

    check {
      script          = "scripts/t_pipeline/check.sh"
      failure_message = "ci-deployer holds a broad or project-wide role. Remove it."

      config {
        environment = { CHECK = "no_broad_roles" }
      }
    }

    solve {
      script = "scripts/t_pipeline/solve.sh"

      config {
        environment = { CHECK = "no_broad_roles" }
      }
    }
  }

  condition "actas_scoped" {
    description = "`ci-deployer` has Service Account User ON `app-runtime` only"

    check {
      script          = "scripts/t_pipeline/check.sh"
      failure_message = "Grant roles/iam.serviceAccountUser to ci-deployer on the app-runtime service account."

      config {
        environment = { CHECK = "actas_scoped" }
      }
    }

    solve {
      script = "scripts/t_pipeline/solve.sh"

      config {
        environment = { CHECK = "actas_scoped" }
      }
    }
  }

  condition "ci_impersonation" {
    description = "staging platform-admin can impersonate `ci-deployer` (granted on the SA, not the project)"

    check {
      script          = "scripts/t_pipeline/check.sh"
      failure_message = "Grant roles/iam.serviceAccountTokenCreator to the staging platform-admin on the ci-deployer service account."

      config {
        environment = { CHECK = "ci_impersonation" }
      }
    }

    solve {
      script = "scripts/t_pipeline/solve.sh"

      config {
        environment = { CHECK = "ci_impersonation" }
      }
    }
  }

  condition "no_keys" {
    description = "`ci-deployer` has NO user-managed keys"

    check {
      script          = "scripts/t_pipeline/check.sh"
      failure_message = "ci-deployer has user-managed keys. Delete them: gcloud iam service-accounts keys delete KEY_ID --iam-account=$CI_DEPLOYER"

      config {
        environment = { CHECK = "no_keys" }
      }
    }

    solve {
      script = "scripts/t_pipeline/solve.sh"

      config {
        environment = { CHECK = "no_keys" }
      }
    }
  }

  condition "tested" {
    description = "A gcloud command succeeded while acting as ci-deployer"

    check {
      script          = "scripts/t_pipeline/check.sh"
      failure_message = "No successful command acting as ci-deployer in ~/week1/commands.log."

      config {
        environment = { CHECK = "tested" }
      }
    }

    solve {
      script = "scripts/t_pipeline/solve.sh"

      config {
        environment = { CHECK = "tested" }
      }
    }
  }

}

resource "task" "t_conditions" {
  description     = "Grant dev-alice time-bound, read-only access in staging"
  success_message = "Access that expires by itself - auditors love this."

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "conditional_binding" {
    description = "`dev-alice` has roles/storage.objectViewer in staging WITH a request.time condition"

    check {
      script          = "scripts/t_conditions/check.sh"
      failure_message = "No conditional roles/storage.objectViewer binding for dev-alice in staging (expression must use request.time)."

      config {
        environment = { CHECK = "conditional_binding" }
      }
    }

    solve {
      script = "scripts/t_conditions/solve.sh"

      config {
        environment = { CHECK = "conditional_binding" }
      }
    }
  }

  condition "expiry_window" {
    description = "The access expires in the future and within 30 days"

    check {
      script          = "scripts/t_conditions/check.sh"
      failure_message = "The timestamp in the condition is in the past or more than 30 days away."

      config {
        environment = { CHECK = "expiry_window" }
      }
    }

    solve {
      script = "scripts/t_conditions/solve.sh"

      config {
        environment = { CHECK = "expiry_window" }
      }
    }
  }

  condition "no_unconditional" {
    description = "`dev-alice` has NO unconditional access in staging"

    check {
      script          = "scripts/t_conditions/check.sh"
      failure_message = "dev-alice has an unconditional binding in staging. Remove it."

      config {
        environment = { CHECK = "no_unconditional" }
      }
    }

    solve {
      script = "scripts/t_conditions/solve.sh"

      config {
        environment = { CHECK = "no_unconditional" }
      }
    }
  }

}

resource "task" "t_org_policy" {
  description     = "Inspect org policies, test a project boundary and look up a quota"
  success_message = "You know where the guard-rails are."

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "read_policies" {
    description = "You read org policies with `gcloud org-policies` successfully"

    check {
      script          = "scripts/t_org_policy/check.sh"
      failure_message = "No successful 'gcloud org-policies list/describe' in ~/week1/commands.log."

      config {
        environment = { CHECK = "read_policies" }
      }
    }

    solve {
      script = "scripts/t_org_policy/solve.sh"

      config {
        environment = { CHECK = "read_policies" }
      }
    }
  }

  condition "boundary_tested" {
    description = "As ci-deployer you tried to read the dev bucket and were denied"

    check {
      script          = "scripts/t_org_policy/check.sh"
      failure_message = "Run: gcloud storage ls gs://$DEV_BUCKET --impersonate-service-account=$CI_DEPLOYER (it should fail)."

      config {
        environment = { CHECK = "boundary_tested" }
      }
    }

    solve {
      script = "scripts/t_org_policy/solve.sh"

      config {
        environment = { CHECK = "boundary_tested" }
      }
    }
  }

  condition "notes" {
    description = "`~/week1/04-org-policy-quotas.md` names constraints and a quota, no `_TODO_` left"

    check {
      script          = "scripts/t_org_policy/check.sh"
      failure_message = "Complete ~/week1/04-org-policy-quotas.md: at least one constraint name (e.g. iam.disableServiceAccountKeyCreation), a quota, and no _TODO_."

      config {
        environment = { CHECK = "notes" }
      }
    }

    solve {
      script = "scripts/t_org_policy/solve.sh"

      config {
        environment = { CHECK = "notes" }
      }
    }
  }

}

resource "task" "t_drill" {
  description     = "Failure drill: break, diagnose, fix narrowly"
  success_message = "Diagnosed with evidence and fixed with one permission. Textbook."

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "broke_it" {
    description = "You removed storage.objects.list from appDeveloper"

    check {
      script          = "scripts/t_drill/check.sh"
      failure_message = "No successful 'gcloud iam roles update appDeveloper ... --remove-permissions=storage.objects.list' in ~/week1/commands.log."

      config {
        environment = { CHECK = "broke_it" }
      }
    }

    solve {
      script = "scripts/t_drill/solve.sh"

      config {
        environment = { CHECK = "broke_it" }
      }
    }
  }

  condition "saw_denial" {
    description = "After the change, dev-alice was denied"

    check {
      script          = "scripts/t_drill/check.sh"
      failure_message = "After removing the permission, run the list command as dev-alice again (wait for propagation) until it is denied."

      config {
        environment = { CHECK = "saw_denial" }
      }
    }

    solve {
      script = "scripts/t_drill/solve.sh"

      config {
        environment = { CHECK = "saw_denial" }
      }
    }
  }

  condition "troubleshooter_saved" {
    description = "Policy Troubleshooter output saved to `~/week1/05-troubleshooter.txt` showing CANNOT_ACCESS"

    check {
      script          = "scripts/t_drill/check.sh"
      failure_message = "Save the troubleshooter output (while access was denied) to ~/week1/05-troubleshooter.txt."

      config {
        environment = { CHECK = "troubleshooter_saved" }
      }
    }

    solve {
      script = "scripts/t_drill/solve.sh"

      config {
        environment = { CHECK = "troubleshooter_saved" }
      }
    }
  }

  condition "narrow_fix" {
    description = "appDeveloper contains storage.objects.list again (exactly 4 permissions)"

    check {
      script          = "scripts/t_drill/check.sh"
      failure_message = "Add storage.objects.list back to appDeveloper - and nothing else."

      config {
        environment = { CHECK = "narrow_fix" }
      }
    }

    solve {
      script = "scripts/t_drill/solve.sh"

      config {
        environment = { CHECK = "narrow_fix" }
      }
    }
  }

  condition "broad_removed" {
    description = "`dev-alice` does NOT hold storage.admin / objectAdmin / editor / owner anywhere in dev"

    check {
      script          = "scripts/t_drill/check.sh"
      failure_message = "Remove the broad role from dev-alice (bucket and project)."

      config {
        environment = { CHECK = "broad_removed" }
      }
    }

    solve {
      script = "scripts/t_drill/solve.sh"

      config {
        environment = { CHECK = "broad_removed" }
      }
    }
  }

  condition "notes" {
    description = "`~/week1/05-failure-drill.md` compares broad vs narrow, no `_TODO_` left"

    check {
      script          = "scripts/t_drill/check.sh"
      failure_message = "Complete ~/week1/05-failure-drill.md (mention roles/storage.admin and appDeveloper) and remove every _TODO_."

      config {
        environment = { CHECK = "notes" }
      }
    }

    solve {
      script = "scripts/t_drill/solve.sh"

      config {
        environment = { CHECK = "notes" }
      }
    }
  }

}

resource "task" "t_deliverable" {
  description     = "Complete the end-of-week deliverable"
  success_message = "Week 1 deliverable complete!"

  config {
    target  = resource.container.cloud_cli
    timeout = "120s"
  }

  condition "identity_map" {
    description = "`03-identity-map.md` lists all five service accounts, no `_TODO_` left"

    check {
      script          = "scripts/t_deliverable/check.sh"
      failure_message = "03-identity-map.md must contain the full email of all 5 service accounts (both platform-admins, dev-alice, ci-deployer, app-runtime) and no _TODO_."

      config {
        environment = { CHECK = "identity_map" }
      }
    }

    solve {
      script = "scripts/t_deliverable/solve.sh"

      config {
        environment = { CHECK = "identity_map" }
      }
    }
  }

  condition "least_privilege" {
    description = "`06-least-privilege.md` covers every role you granted, no `_TODO_` left"

    check {
      script          = "scripts/t_deliverable/check.sh"
      failure_message = "06-least-privilege.md must mention appDeveloper, run.developer, artifactregistry.writer, serviceAccountUser, serviceAccountTokenCreator and storage.objectViewer, with no _TODO_."

      config {
        environment = { CHECK = "least_privilege" }
      }
    }

    solve {
      script = "scripts/t_deliverable/solve.sh"

      config {
        environment = { CHECK = "least_privilege" }
      }
    }
  }

  condition "command_log" {
    description = "`commands.log` contains at least 15 gcloud commands"

    check {
      script          = "scripts/t_deliverable/check.sh"
      failure_message = "commands.log has fewer than 15 gcloud commands - run your commands in the lab terminals."

      config {
        environment = { CHECK = "command_log" }
      }
    }

    solve {
      script = "scripts/t_deliverable/solve.sh"

      config {
        environment = { CHECK = "command_log" }
      }
    }
  }

  condition "bundled" {
    description = "`~/week1/week1-deliverable.md` bundles all notes and the command log"

    check {
      script          = "scripts/t_deliverable/check.sh"
      failure_message = "Create ~/week1/week1-deliverable.md (see Step 3) - it must include the identity map, least-privilege table and the command log."

      config {
        environment = { CHECK = "bundled" }
      }
    }

    solve {
      script = "scripts/t_deliverable/solve.sh"

      config {
        environment = { CHECK = "bundled" }
      }
    }
  }

}
