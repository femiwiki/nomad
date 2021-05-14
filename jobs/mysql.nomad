job "mysql" {
  datacenters = ["dc1"]

  group "mysql" {
    volume "mysql" {
      type      = "csi"
      source    = "mysql"
      read_only = false
    }

    task "mysql" {
      driver = "docker"

      volume_mount {
        volume      = "mysql"
        destination = "/srv/mysql"
        read_only   = false
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/mysql/my.cnf"
        destination = "local/my.cnf"
        mode        = "file"

        options { checksum = "md5:5a91e2777c4fc83f1ba87acea88bb25b" }
      }

      config {
        image             = "mysql/mysql-server:8.0.25"
        volumes           = ["local/my.cnf:/etc/mysql/my.cnf"]
        memory_hard_limit = 800
      }

      resources {
        memory = 400
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
