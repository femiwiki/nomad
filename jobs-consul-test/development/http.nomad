variable "caddyfile_for_dev" {
  type    = string
  default = <<EOF
{
  # Global options
  auto_https off
  order mwcache before rewrite
}
http://localhost:8080 http://127.0.0.1:8080 http://192.168.0.2:8080
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

# Proxy requests to RESTBase
# Reference:
#   https://www.mediawiki.org/wiki/RESTBase/Installation#Proxy_requests_to_RESTBase_from_your_webserver
reverse_proxy /localhost/* {$NOMAD_UPSTREAM_ADDR_restbase}

log {
  output stdout
}
EOF
}

job "http" {
  datacenters = ["dc1"]

  group "http" {
    task "http" {
      driver = "docker"

      template {
        # Overwrite production Caddyfile
        data        = var.caddyfile_for_dev
        destination = "local/Caddyfile"
      }

      config {
        image   = "ghcr.io/femiwiki/mediawiki:latest"
        command = "caddy"
        args    = ["run"]
        ports   = ["http"]

        # Mount volumes into the container
        # Reference: https://www.nomadproject.io/docs/drivers/docker#mounts
        mounts = [
          {
            type     = "volume"
            source   = "caddy"
            target   = "/etc/caddycerts"
            readonly = false
          },
          {
            type     = "volume"
            source   = "sitemap"
            target   = "/srv/femiwiki.com/sitemap"
            readonly = false
          },
        ]

        volumes = [
          # Overwrite production Caddyfile
          "local/Caddyfile:/srv/femiwiki.com/Caddyfile"
        ]
      }
    }

    network {
      mode = "bridge"

      port "http" {
        to = 8080
      }
    }

    service {
      name         = "http"
      port         = "http"
      address_mode = "alloc"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=PathPrefix(`/`) || Host(`femiwiki.com`)",
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
      }
    }
  }
}
