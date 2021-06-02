job "http" {
  datacenters = ["dc1"]

  group "http" {
    volume "caddycerts" {
      type            = "csi"
      source          = "caddycerts"
      read_only       = false
      access_mode     = "single-node-writer"
      attachment_mode = "file-system"
    }

    task "http" {
      driver = "docker"

      volume_mount {
        volume      = "caddycerts"
        destination = "/etc/caddycerts"
        read_only   = false
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/caddy/Caddyfile"
        destination = "local/Caddyfile"
        mode        = "file"
      }

      config {
        image   = "ghcr.io/femiwiki/mediawiki:2021-05-28T14-01-0b1f9738"
        command = "caddy"
        args    = ["run"]

        network_mode = "host"

        volumes = ["local/Caddyfile:/srv/femiwiki.com/Caddyfile"]

        # Mount volume into the container
        # Reference: https://www.nomadproject.io/docs/drivers/docker#mounts
        mounts = [
          {
            type     = "volume"
            target   = "/srv/femiwiki.com/sitemap"
            source   = "sitemap"
            readonly = false
          },
        ]

        # Increase max fd number
        # https://github.com/femiwiki/docker-mediawiki/issues/467
        ulimit {
          nofile = "20000:40000"
        }
        memory_hard_limit = 400
      }

      resources {
        memory = 100
      }

      env {
        CADDYPATH     = "/etc/caddycerts"
        FASTCGI_ADDR  = "127.0.0.1:9000"
        RESTBASE_ADDR = "127.0.0.1:7231"
      }
    }

    restart {
      attempts = 0
    }
  }

  reschedule {
    attempts       = 3
    interval       = "120s"
    delay          = "5s"
    delay_function = "constant"
    unlimited      = false
  }

  update {
    auto_revert = true
  }
}
