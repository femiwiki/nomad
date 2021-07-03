job "mysql" {
  datacenters = ["dc1"]

  group "mysql" {
    # Disabled during test period
    # volume "mysql" {
    #   type      = "csi"
    #   source    = "mysql"
    #   read_only = false
    # }

    task "mysql" {
      driver = "docker"

      # Disabled during test period
      # volume_mount {
      #   volume      = "mysql"
      #   destination = "/srv/mysql"
      #   read_only   = false
      # }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/mysql/my.cnf"
        destination = "local/my.cnf"
        mode        = "file"
      }

      config {
        image   = "mysql/mysql-server:8.0.25"
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
    }

    service {
      name = "mysql"
      port = "3306"

      connect {
        sidecar_service {}

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
    attempts  = 3
    interval  = "24h"
    delay     = "10s"
    unlimited = false
  }

  update {
    auto_revert = true
  }
}
