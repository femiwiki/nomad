job "fastcgi" {
  datacenters = ["dc1"]

  group "fastcgi" {
    task "fastcgi" {
      driver = "docker"

      artifact {
        source      = "https://raw.githubusercontent.com/femiwiki/docker-mediawiki/main/configs/secret.php.example"
        destination = "secrets/secrets.php"
        mode        = "file"
      }

      artifact {
        source      = "https://raw.githubusercontent.com/femiwiki/docker-mediawiki/main/development/site-list.xml"
        destination = "local/site-list.xml"
        mode        = "file"
      }

      template {
        data        = var.hotfix
        destination = "local/Hotfix.php"
        change_mode = "noop"
      }

      config {
        image = "ghcr.io/femiwiki/mediawiki:latest"
        ports = ["fastcgi"]

        volumes = [
          "secrets/secrets.php:/a/secret.php",
          "local/Hotfix.php:/a/Hotfix.php",
          "local/site-list.xml:/a/site-list.xml",
        ]

        mounts = [
          {
            type     = "volume"
            source   = "sitemap"
            target   = "/srv/femiwiki.com/sitemap"
            readonly = false
          },
        ]
      }

      env {
        MEDIAWIKI_DEBUG_MODE              = "1"
        MEDIAWIKI_SERVER                  = "http://localhost"
        MEDIAWIKI_DOMAIN_FOR_NODE_SERVICE = "localhost"
      }
    }

    network {
      mode = "bridge"

      port "fastcgi" {
        to = 9000
      }
    }

    service {
      name         = "fastcgi"
      port         = "fastcgi"
      address_mode = "alloc"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "mysql"
              local_bind_port  = 3306
            }

            upstreams {
              destination_name = "memcached"
              local_bind_port  = 11211
            }

            upstreams {
              destination_name = "restbase"
              local_bind_port  = 7231
            }

            upstreams {
              destination_name = "mathoid"
              local_bind_port  = 10044
            }
          }
        }
      }
    }
  }
}

variable "hotfix" {
  type    = string
  default = <<EOF
<?php
// Use this file for hotfixes

// Examples:
//
// $wgDebugToolbar = false;
// $wgDefaultSkin = 'vector';
EOF
}
