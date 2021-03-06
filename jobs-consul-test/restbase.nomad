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
        PARSOID_URI        = "http://${NOMAD_UPSTREAM_ADDR_http}/rest.php"
        MATHOID_URI        = "http://${NOMAD_UPSTREAM_ADDR_mathoid}"
      }
    }

    network {
      mode = "bridge"
    }

    service {
      name = "restbase"
      port = "7231"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "http"
              local_bind_port  = 8080
            }

            upstreams {
              destination_name = "mathoid"
              local_bind_port  = 10044
            }
          }
        }

        sidecar_task {
          resources {
            memory     = 300
            memory_max = 500
          }
        }
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
