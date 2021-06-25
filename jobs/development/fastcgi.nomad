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
          }
        ]

        network_mode = "host"
      }

      resources {
        memory     = 400
        memory_max = 800
      }

      env {
        NOMAD_UPSTREAM_ADDR_http          = "127.0.0.1:8080"
        NOMAD_UPSTREAM_ADDR_mysql         = "127.0.0.1:3306"
        NOMAD_UPSTREAM_ADDR_memcached     = "127.0.0.1:11211"
        NOMAD_UPSTREAM_ADDR_restbase      = "127.0.0.1:7231"
        NOMAD_UPSTREAM_ADDR_mathoid       = "127.0.0.1:10044"
        MEDIAWIKI_DEBUG_MODE              = "1"
        MEDIAWIKI_SERVER                  = "http://localhost:8080"
        MEDIAWIKI_DOMAIN_FOR_NODE_SERVICE = "localhost"
        # MEDIAWIKI_SKIP_INSTALL        = "1"
        # MEDIAWIKI_SKIP_IMPORT_SITES   = "1"
        # MEDIAWIKI_SKIP_UPDATE         = "1"
      }
    }
  }
}
