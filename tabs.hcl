resource "terminal" "shell" {
  target            = resource.container.cloud_cli
  shell             = "/bin/bash"
  working_directory = "/root/week1"
}

resource "terminal" "shell2" {
  target            = resource.container.cloud_cli
  shell             = "/bin/bash"
  working_directory = "/root/week1"
}

# Editor opened on the learner's deliverable folder (~/week1)
resource "editor" "notes" {
  workspace "week1" {
    target    = resource.container.cloud_cli
    directory = "/root/week1"
  }
}

# Console logins for the read-only "learner" user in both projects
resource "cloud_credentials" "gcp" {
  google_project {
    target = resource.google_project.northwind-dev
    users  = ["learner"]
  }

  google_project {
    target = resource.google_project.northwind-staging
    users  = ["learner"]
  }
}

resource "external_website" "console" {
  url                = "https://console.cloud.google.com/iam-admin/troubleshooter"
  open_in_new_window = true
}

# Hidden-until-opened help tabs
resource "note" "cheatsheet" {
  file = "notes/cheatsheet.md"
}

resource "note" "troubleshooting" {
  file = "notes/troubleshooting.md"
}
