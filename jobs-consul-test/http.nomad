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

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/res/robots.txt"
        destination = "local/robots.txt"
        mode        = "file"
      }

      config {
        image   = "ghcr.io/femiwiki/mediawiki:2021-06-18T04-57-20822934"
        command = "caddy"
        args    = ["run"]
        ports   = ["http"]

        volumes = [
          "local/Caddyfile:/srv/femiwiki.com/Caddyfile",
          "local/robots.txt:/srv/femiwiki.com/robots.txt",
        ]

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
      }

      resources {
        memory     = 100
        memory_max = 400
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
          resources {
            memory     = 300
            memory_max = 500
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
