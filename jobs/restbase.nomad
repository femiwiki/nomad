job "restbase" {
  datacenters = ["dc1"]

  group "restbase" {
    task "restbase" {
      driver = "docker"

      config {
        image = "ghcr.io/femiwiki/restbase:2021-05-25T01-32-1a60cdd5"

        mounts = [
          {
            type     = "volume"
            target   = "/srv/restbase.sqlite3"
            source   = "restbase"
            readonly = false
          }
        ]

        network_mode = "host"
      }

      resources {
        memory     = 100
        memory_max = 400
      }

      env {
        RESTBASE_NUM_WORKERS  = "0"
        MEDIAWIKI_APIS_DOMAIN = "femiwiki.com"
        # Workaround for https://github.com/femiwiki/femiwiki/issues/151
        MEDIAWIKI_APIS_URI = "https://femiwiki.com/api.php"
        PARSOID_URI        = "http://127.0.0.1:80/rest.php"
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
