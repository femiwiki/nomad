variable "mysql_password_mediawiki" {
  type    = string
  default = ""
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
        image   = "ghcr.io/femiwiki/backupbot:2023-01-08t22-00-4d528e99"
        volumes = ["secrets/secrets.php:/a/secrets.php"]
      }

      env {
        LOCAL_SETTINGS = "/a/secrets.php"
        WG_DB_SERVER   = NOMAD_UPSTREAM_ADDR_mysql
        WG_DB_USER     = "mediawiki"
        WG_DB_PASSWORD = var.mysql_password_mediawiki
      }

      resources {
        memory = 100
      }
    }

    network {
      mode = "bridge"
    }
  }

  reschedule {
    unlimited = true
  }

  update {
    auto_revert = true
  }
}
