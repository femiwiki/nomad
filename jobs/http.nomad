job "http" {
  datacenters = ["dc1"]

  constraint {
    attribute = meta.main_elastic_ip
    value     = "true"
  }

  group "http" {
    task "http" {
      driver = "docker"

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/caddy/Caddyfile"
        destination = "local/Caddyfile.tpl"
        mode        = "file"
        options { checksum = "md5:3898f8a9e8b3e1e2190ee4d62146b9a7" }
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
        image   = "ghcr.io/femiwiki/femiwiki:2025-01-27T13-08-cf06d12a"
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
        memory     = 120
        memory_max = 140
      }

      env {
        FASTCGI_ADDR        = NOMAD_UPSTREAM_ADDR_fastcgi
        S3_USE_IAM_PROVIDER = true
        S3_HOST             = "s3.ap-northeast-1.amazonaws.com"
        S3_BUCKET           = "femiwiki-secrets"
        S3_PREFIX           = "caddycerts"
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
