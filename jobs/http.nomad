job "http" {
  datacenters = ["dc1"]

  constraint {
    attribute = meta.main_elastic_ip
    value     = "true"
  }

  group "http" {
    volume "caddycerts" {
      type            = "csi"
      source          = "caddycerts_green"
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
        destination = "local/Caddyfile.tpl"
        mode        = "file"
        options { checksum = "md5:9d57fb57bdb833f3f3b47f3624176a46" }
      }
      template {
        source      = "local/Caddyfile.tpl"
        destination = "local/Caddyfile"
        change_mode = "script"
        change_script {
          command = "caddy"
          args    = ["reload"]
        }
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/res/robots.txt"
        destination = "local/robots.txt"
        mode        = "file"

        options { checksum = "md5:ff514e2b6c7f211ddc49203939793fae" }
      }

      config {
        image   = "ghcr.io/femiwiki/femiwiki:2024-06-30T00-53-34439279"
        command = "caddy"
        args    = ["run"]

        volumes = [
          "local/Caddyfile:/srv/femiwiki.com/Caddyfile",
          "local/robots.txt:/srv/femiwiki.com/robots.txt",
        ]

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
      }

      resources {
        memory     = 100
        memory_max = 130
      }

      env {
        CADDYPATH    = "/etc/caddycerts"
        FASTCGI_ADDR = NOMAD_UPSTREAM_ADDR_fastcgi
      }

    }

    network {
      mode = "bridge"

      port "http" {
        static = 80
      }

      port "https" {
        static = 443
      }
    }

    service {
      name = "http"
      port = "80"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "fastcgi"
              local_bind_port  = 9000
            }
          }
        }

        sidecar_task {
          config {
            memory_hard_limit = 60
          }
          resources {
            memory = 40
          }
        }
      }
    }

    # Avoid hitting limit too fast.
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
