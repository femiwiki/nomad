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
        source      = "https://raw.githubusercontent.com/femiwiki/docker-mediawiki/main/configs/LocalSettings.php"
        destination = "local/LocalSettings.php"
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
        image             = "ghcr.io/femiwiki/mediawiki:latest"
        network_mode      = "host"
        memory_hard_limit = 600

        volumes = [
          "secrets/secrets.php:/a/secret.php",
          "local/LocalSettings.php:/a/LocalSettings.php",
          "local/Hotfix.php:/a/Hotfix.php",
          "local/site-list.xml:/a/site-list.xml",
        ]

        mounts = [
          {
            type     = "volume"
            target   = "/srv/femiwiki.com/sitemap"
            source   = "sitemap"
            readonly = false
          }
        ]
      }

      env {
        MEDIAWIKI_DEBUG_MODE              = "1"
        MEDIAWIKI_SERVER                  = "http://127.0.0.1"
        MEDIAWIKI_DOMAIN_FOR_NODE_SERVICE = "localhost"
        NOMAD_UPSTREAM_ADDR_http          = "127.0.0.1:80"
        NOMAD_UPSTREAM_ADDR_mysql         = "127.0.0.1:3306"
        NOMAD_UPSTREAM_ADDR_memcached     = "127.0.0.1:11211"
        NOMAD_UPSTREAM_ADDR_parsoid       = "127.0.0.1:8000"
        NOMAD_UPSTREAM_ADDR_restbase      = "127.0.0.1:7231"
        NOMAD_UPSTREAM_ADDR_mathoid       = "127.0.0.1:10044"
      }

      resources {
        memory = 100
      }
    }
  }
}
