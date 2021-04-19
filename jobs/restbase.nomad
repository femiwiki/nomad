job "restbase" {
  datacenters = ["dc1"]

  group "restbase" {
    task "restbase" {
      driver = "docker"

      config {
        image = "ghcr.io/femiwiki/restbase:2021-04-17T11-25-e5b25017"

        mounts = [
          {
            type     = "volume"
            target   = "/srv/restbase.sqlite3"
            source   = "restbase"
            readonly = false
          }
        ]

        network_mode      = "host"
        memory_hard_limit = 400
      }

      resources {
        memory = 70
      }

      env {
        RESTBASE_NUM_WORKERS  = "0"
        MEDIAWIKI_APIS_DOMAIN = "femiwiki.com"
        # Workaround for https://github.com/femiwiki/femiwiki/issues/151
        MEDIAWIKI_APIS_URI = "https://femiwiki.com/api.php"
        PARSOID_URI        = "http://127.0.0.1:8000"
        MATHOID_URI        = "http://127.0.0.1:10044"
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
