variable "hotfix" {
  type    = string
  default = <<EOF
<?php
// Use this file for hotfixes
// Examples:

// $wgGroupPermissions['*']['edit'] = true;
// $wgDebugToolbar = false;
// $wgDefaultSkin = 'vector';
EOF
}

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

      # Overwrite to set the url of femiwiki to http://127.0.0.1/
      artifact {
        source      = "https://raw.githubusercontent.com/femiwiki/docker-mediawiki/main/development/site-list.xml"
        destination = "local/site-list.xml"
        mode        = "file"
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/php/php.ini"
        destination = "local/php.ini"
        mode        = "file"
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/php/php-fpm.conf"
        destination = "local/php-fpm.conf"
        mode        = "file"
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/php/www.conf"
        destination = "local/www.conf"
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
            target   = "/srv/femiwiki.com/sitemap"
            source   = "sitemap"
            readonly = false
          },
        ]
      }

      resources {
        memory     = 400
        memory_max = 800
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
          }
        }
      }
    }
  }
}
