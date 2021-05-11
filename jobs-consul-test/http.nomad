job "http" {
  datacenters = ["dc1"]

  group "http" {
    task "http" {
      driver = "docker"

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/caddy/Caddyfile-consul-test"
        destination = "local/Caddyfile"
        mode        = "file"
      }

      config {
        image   = "ghcr.io/femiwiki/mediawiki:2021-04-19T12-14-11fd8960"
        command = "caddy"
        args    = ["run"]
        volumes = ["local/Caddyfile:/srv/femiwiki.com/Caddyfile"]
        ports   = ["http"]

        # Mount volume into the container
        # Reference: https://www.nomadproject.io/docs/drivers/docker#mounts
        mounts = [
          {
            type     = "volume"
            source   = "sitemap"
            target   = "/srv/femiwiki.com/sitemap"
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
        CADDYPATH = "/etc/caddycerts"
      }
    }

    network {
      mode = "bridge"

      port "http" {
        to = 80
      }
    }

    service {
      name         = "http"
      port         = "http"
      address_mode = "alloc"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=PathPrefix(`/`) || Host(`femiwiki.com`)",
        "traefik.http.routers.http.tls=true",
        "traefik.http.routers.http.tls.certresolver=myresolver",
        "traefik.http.routers.http.tls.domains[0].main=femiwiki.com",
        "traefik.http.routers.http.tls.domains[0].sans=*.femiwiki.com",
      ]

      connect {
        sidecar_service {
          tags = [
            # Avoid "Router defined multiple times with different configurations"
            "traefik.enable=false",
          ]

          proxy {
            upstreams {
              destination_name = "fastcgi"
              local_bind_port  = 9000
            }

            upstreams {
              destination_name = "restbase"
              local_bind_port  = 7231
            }
          }
        }

        sidecar_task {
          config {
            memory_hard_limit = 500
          }
          resources {
            memory = 300
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
