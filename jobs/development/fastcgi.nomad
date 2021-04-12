job "fastcgi" {
  datacenters = ["dc1"]

  group "fastcgi" {
    volume "configs" {
      type      = "host"
      source    = "configs"
      read_only = true
    }

    task "fastcgi" {
      driver = "docker"

      config {
        image             = "ghcr.io/femiwiki/mediawiki:caddy-mwcache"
        network_mode      = "host"
        memory_hard_limit = 600
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

      volume_mount {
        volume      = "configs"
        destination = "/a"
        read_only   = true
      }
    }
  }
}
