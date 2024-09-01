variable "test" {
  type        = bool
  description = "Uses jobs for the test server. Without CSI"
  default     = false
}

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
        image        = "ghcr.io/femiwiki/backupbot:2023-01-08t22-00-4d528e99"
        volumes      = ["secrets/secrets.php:/a/secrets.php"]
        network_mode = "host"
      }

      env {
        LOCAL_SETTINGS = "/a/secrets.php"
      }

      resources {
        memory = 100
      }
    }

    dynamic "network" {
      for_each = var.test ? [{}] : []
      content {
        mode = "bridge"
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
