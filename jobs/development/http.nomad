variable "caddyfile_for_dev" {
  type    = string
  default = <<EOF
{
  # Global options
  auto_https off
  order mwcache before rewrite
}
http://127.0.0.1:8080 http://localhost:8080
root * /srv/femiwiki.com
php_fastcgi 127.0.0.1:9000
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
reverse_proxy /localhost/* 127.0.0.1:7231

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
        # Overwrite the default caddyfile provided by femiwiki:mediawiki
        data        = var.caddyfile_for_dev
        destination = "local/Caddyfile"
      }

      config {
        image   = "ghcr.io/femiwiki/mediawiki:latest"
        command = "caddy"
        args    = ["run"]

        # Mount volumes into the container
        # Reference: https://www.nomadproject.io/docs/drivers/docker#mounts
        mounts = [
          {
            type     = "volume"
            target   = "/etc/caddycerts"
            source   = "caddy"
            readonly = false
          },
          {
            type     = "volume"
            target   = "/srv/femiwiki.com/sitemap"
            source   = "sitemap"
            readonly = false
          }
        ]

        volumes = [
          # Overwrite production Caddyfile
          "local/Caddyfile:/srv/femiwiki.com/Caddyfile"
        ]

        network_mode      = "host"
      }

      resources {
        memory = 80
        memory_max = 400
      }
    }
  }
}
