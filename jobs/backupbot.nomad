job "backupbot" {
  datacenters = ["dc1"]

  group "backupbot" {
    volume "secrets" {
      type      = "host"
      source    = "secrets"
      read_only = true
    }

    task "backupbot" {
      driver = "docker"

      config {
        image             = "ghcr.io/femiwiki/backupbot:2021-04-02T01-01-9103fae5"
        network_mode      = "host"
        memory_hard_limit = 600
      }

      volume_mount {
        volume      = "secrets"
        destination = "/a"
        read_only   = true
      }

      env {
        LOCAL_SETTINGS = "/a/secret.php"
      }

      resources {
        memory = 150
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
