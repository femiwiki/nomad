variable "green" {
  type    = bool
  default = false
}

locals {
  blue = !var.green
}

job "mysql" {
  datacenters = ["dc1"]

  group "mysql" {
    dynamic "volume" {
      for_each = local.blue ? [{}] : []
      labels   = ["mysql"]

      content {
        type            = "csi"
        source          = "mysql"
        read_only       = false
        access_mode     = "single-node-writer"
        attachment_mode = "file-system"
      }
    }

    task "mysql" {
      driver = "docker"

      dynamic "volume_mount" {
        for_each = local.blue ? [{}] : []

        content {
          volume      = "mysql"
          destination = "/srv/mysql"
          read_only   = false
        }
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/mysql/my.cnf"
        destination = "local/my.cnf"
        mode        = "file"

        options { checksum = "md5:e024ebdad91fefa75450e784e17cf150" }
      }

      config {
        image   = "mysql/mysql-server:8.0.32"
        volumes = ["local/my.cnf:/etc/mysql/my.cnf"]
      }

      resources {
        memory     = 400
        memory_max = 700
      }

      env {
        MYSQL_RANDOM_ROOT_PASSWORD = "yes"
      }
    }

    network {
      mode = "bridge"
      dynamic "port" {
        for_each = local.blue ? [{}] : []
        labels   = ["network"]

        content {
          # Accessed by Backupbot
          static = 3306
        }
      }
    }

    dynamic "service" {
      for_each = var.green ? [{}] : []
      content {
        name = "mysql"
        port = "3306"

        connect {
          sidecar_service {}

          sidecar_task {
            config {
              memory_hard_limit = 300
            }
            resources {
              memory = 20
            }
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
