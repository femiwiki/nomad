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

      template {
        data        = var.hotfix
        destination = "local/Hotfix.php"
      }

      config {
        image             = "ghcr.io/femiwiki/mediawiki:caddy-mwcache"
        network_mode      = "host"
        memory_hard_limit = 600

        volumes = [
          # Overwrite the default Hotfix.php provided by femiwiki/mediawiki
          "local/Hotfix.php:/config/mediawiki/Hotfix.php"
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

      volume_mount {
        volume      = "configs"
        destination = "/a"
        read_only   = true
      }
    }
  }
}

variable "hotfix" {
  type    = string
  default = <<EOF
<?php
// Use this file for hot fixes

// Maintenance
//// 점검이 끝나면 아래 라인 주석처리한 뒤, 아래 문서 내용을 비우면 됨
//// https://femiwiki.com/w/%EB%AF%B8%EB%94%94%EC%96%B4%EC%9C%84%ED%82%A4:Sitenotice
// $wgReadOnly = '데이터베이스 업그레이드 작업이 진행 중입니다. 작업이 진행되는 동안 사이트 이용이 제한됩니다.';

//// 업로드를 막고싶을때엔 아래 라인 주석 해제하면 됨
// $wgEnableUploads = false;
EOF
}
