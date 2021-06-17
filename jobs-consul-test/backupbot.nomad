job "backupbot" {
  datacenters = ["dc1"]

  group "backupbot" {
    task "backupbot" {
      driver = "docker"

      artifact {
        source      = "s3::https://femiwiki-secrets.s3-ap-northeast-1.amazonaws.com/secrets.php"
        destination = "secrets/secrets.php"
        mode        = "file"
      }

      config {
        image   = "ghcr.io/femiwiki/backupbot:2021-05-08T11-12-9ef5f0fa"
        volumes = ["secrets/secrets.php:/a/secrets.php"]
      }

      env {
        LOCAL_SETTINGS = "/a/secrets.php"
      }

      resources {
        memory = 100
      }
    }

    network {
      mode = "bridge"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "mysql"
              local_bind_port  = 3306
            }
          }
        }

        sidecar_task {
          resources {
            memory     = 30
            memory_max = 300
          }
        }
      }
    }
  }

  reschedule {
    attempts  = 1
    interval  = "24h"
    unlimited = false
  }

  update {
    auto_revert = true
  }
}
