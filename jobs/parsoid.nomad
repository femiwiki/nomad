job "parsoid" {
  datacenters = ["dc1"]

  group "parsoid" {
    # Init Task Lifecycle
    # See https://www.nomadproject.io/docs/job-specification/lifecycle#init-task-pattern
    task "wait-for-mediawiki" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "sh"
        args    = ["-c", "while ! ncat --send-only 127.0.0.1 80 < /dev/null; do sleep 1; done"]
      }
    }

    task "parsoid" {
      driver = "docker"

      config {
        image             = "ghcr.io/femiwiki/parsoid:2021-04-17T11-06-0e9f9fb2"
        network_mode      = "host"
        memory_hard_limit = 400
      }

      resources {
        memory = 120
      }

      env {
        PARSOID_NUM_WORKERS   = "0"
        MEDIAWIKI_LINTING     = "true"
        MEDIAWIKI_APIS_DOMAIN = "femiwiki.com"
        MEDIAWIKI_APIS_URI    = "http://127.0.0.1/api.php"
      }
    }
  }

  reschedule {
    attempts  = 3
    interval  = "24h"
    delay     = "10s"
    unlimited = false
  }

  update {
    auto_revert = true
  }
}
