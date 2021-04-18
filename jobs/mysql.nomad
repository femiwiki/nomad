job "mysql" {
  datacenters = ["dc1"]

  group "mysql" {
    volume "mysql" {
      type      = "host"
      source    = "mysql"
      read_only = false
    }

    task "mysql" {
      driver = "docker"

      config {
        image   = "mysql:8.0.23"
        volumes = ["local/custom.cnf:/etc/mysql/conf.d/custom.cnf"]
        args = [
          "--default-authentication-plugin=mysql_native_password",
          "--datadir", "/srv/mysql"
        ]
        memory_hard_limit = 1000
      }

      resources {
        memory = 600
      }

      volume_mount {
        volume      = "mysql"
        destination = "/srv/mysql"
        read_only   = false
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/mysql/custom.cnf"
        destination = "local/custom.cnf"
        mode        = "file"
      }

      env {
        MYSQL_RANDOM_ROOT_PASSWORD = "yes"
      }
    }

    network {
      mode = "bridge"

      port "mysql" {
        static = 3306
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
