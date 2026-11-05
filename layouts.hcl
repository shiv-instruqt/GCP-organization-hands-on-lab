resource "layout" "workbench" {
  column {
    width = "40"
    instructions {}
  }

  column {
    width = "60"

    tab "terminal" {
      title  = "Terminal"
      target = resource.terminal.shell
      active = true
    }

    tab "terminal2" {
      title  = "Terminal 2"
      target = resource.terminal.shell2
    }

    tab "notes" {
      title  = "Week 1 Notes (editor)"
      target = resource.editor.notes
    }

    tab "credentials" {
      title  = "Console Login"
      target = resource.cloud_credentials.gcp
    }

    tab "console" {
      title  = "GCP Console"
      target = resource.external_website.console
    }

    tab "cheatsheet" {
      title  = "Hints & Cheat Sheet"
      target = resource.note.cheatsheet
    }

    tab "troubleshooting" {
      title  = "Troubleshooting"
      target = resource.note.troubleshooting
    }
  }
}

resource "layout" "reading" {
  column {
    width = "55"
    instructions {}
  }

  column {
    width = "45"

    tab "terminal" {
      title  = "Terminal"
      target = resource.terminal.shell
      active = true
    }

    tab "credentials" {
      title  = "Console Login"
      target = resource.cloud_credentials.gcp
    }

    tab "cheatsheet" {
      title  = "Hints & Cheat Sheet"
      target = resource.note.cheatsheet
    }
  }
}
