variable "test" {
  type        = bool
  description = "Uses jobs for the test server. Without certification."
  default     = false
}

locals {
  main = !var.test
}

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
      dynamic "artifact" {
        for_each = local.main ? [{}] : []

        content {
          source      = "https://github.com/femiwiki/nomad/raw/main/caddy/Caddyfile"
          destination = "local/Caddyfile"
          mode        = "file"

          options { checksum = "md5:ee0300e384afa6aca74f09a44323ee6e" }
        }
      }
      dynamic "template" {
        for_each = var.test ? [{}] : []

        content {
          data        = var.caddyfile_for_test
          destination = "local.Caddyfile"
        }
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/res/robots.txt"
        destination = "local/robots.txt"
        mode        = "file"

        options { checksum = "md5:0f781bd4d8e87bbc4701a955ef319045" }
      }

      config {
        image   = "ghcr.io/femiwiki/femiwiki:2024-06-30T00-53-34439279"
        command = "caddy"
        args    = ["run"]

        network_mode = "host"

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
        CADDYPATH    = "/etc/caddycerts"
        FASTCGI_ADDR = var.test ? NOMAD_UPSTREAM_ADDR_fastcgi : "127.0.0.1:9000"
      }
    }

    dynamic "network" {
      for_each = var.test ? [{}] : []
      content {
        mode = "bridge"

        port "http" {
          static = 80
        }

        port "https" {
          static = 443
        }
      }
    }

    dynamic "service" {
      for_each = var.test ? [{}] : []
      content {
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
              memory_hard_limit = 500
            }
            resources {
              memory = 20
            }
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

variable "caddyfile_for_test" {
  type    = string
  default = <<EOF
{
  # Global options
  auto_https off
  order mwcache before rewrite
}
http://127.0.0.1:{$NOMAD_HOST_PORT_http} http://localhost:{$NOMAD_HOST_PORT_http}
root * /srv/femiwiki.com
php_fastcgi {$NOMAD_UPSTREAM_ADDR_fastcgi}
file_server
encode gzip
mwcache {
	ristretto {
		num_counters 100000
		max_cost 10000
		buffer_items 64
	}
  purge_acl {
    10.0.0.0/8
    127.0.0.1
  }
}
header {
  # Enable XSS filtering for legacy browsers
  X-XSS-Protection "1; mode=block"
  # Block content sniffing, and enable Cross-Origin Read Blocking
  X-Content-Type-Options "nosniff"
  # Avoid clickjacking
  X-Frame-Options "DENY"
}
rewrite /w/api.php /api.php
rewrite /w/* /index.php

EOF
}
