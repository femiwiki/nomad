job "fastcgi" {
  datacenters = ["dc1"]

  group "fastcgi" {
    # Init Task Lifecycle
    # See https://www.nomadproject.io/docs/job-specification/lifecycle#init-task-pattern
    task "wait-for-backend" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "sh"
        args = [
          "-c",
          join(";", [
            "while ! ncat --send-only 127.0.0.1 3306 < /dev/null; do sleep 1; done",
            "while ! ncat --send-only 127.0.0.1 11211 < /dev/null; do sleep 1; done"
          ])
        ]
      }
    }

    volume "secrets" {
      type   = "csi"
      source = "secrets"
      // Use writable mode
      // https://github.com/femiwiki/nomad/issues/18
      read_only = false
    }

    task "fastcgi" {
      driver = "docker"

      template {
        data        = var.hotfix
        destination = "local/Hotfix.php"
      }

      config {
        image = "ghcr.io/femiwiki/mediawiki:2021-04-20T02-26-9a42ee4a"

        mounts = [
          {
            type     = "volume"
            target   = "/tmp/cache"
            source   = "l18n_cache"
            readonly = false
          }
        ]

        volumes = [
          # Overwrite the default Hotfix.php provided by femiwiki/mediawiki
          "local/Hotfix.php:/srv/femiwiki.com/Hotfix.php"
        ]

        network_mode      = "host"
        memory_hard_limit = 600
      }

      volume_mount {
        volume      = "secrets"
        destination = "/a"
        // Use writable mode
        // https://github.com/femiwiki/nomad/issues/18
        read_only = false
      }

      env {
        # TODO Remove comment completely if https://github.com/femiwiki/femiwiki/issues/245 is solved
        MEDIAWIKI_SERVER              = "https://test.femiwiki.com"
        NOMAD_UPSTREAM_ADDR_http      = "127.0.0.1:80"
        NOMAD_UPSTREAM_ADDR_memcached = "127.0.0.1:11211"
        NOMAD_UPSTREAM_ADDR_parsoid   = "127.0.0.1:8000"
        NOMAD_UPSTREAM_ADDR_restbase  = "127.0.0.1:7231"
        NOMAD_UPSTREAM_ADDR_mathoid   = "127.0.0.1:10044"
        MEDIAWIKI_SKIP_INSTALL        = "1"
        MEDIAWIKI_SKIP_UPDATE         = "1"
        MEDIAWIKI_SKIP_IMPORT_SITES   = "1"
      }

      resources {
        memory = 110
      }
    }
  }

  reschedule {
    attempts  = 3
    interval  = "24h"
    delay     = "10s"
    unlimited = false
  }

  update {
    auto_revert = true
  }
}

variable "hotfix" {
  type    = string
  default = <<EOF
<?php
// Use this file for hot fixes

// Remove this after closing of https://github.com/femiwiki/femiwiki/issues/245
$wgDBserver = '172.31.17.64';

// Maintenance
//// 점검이 끝나면 아래 라인 주석처리한 뒤, 아래 문서 내용을 비우면 됨
//// https://femiwiki.com/w/%EB%AF%B8%EB%94%94%EC%96%B4%EC%9C%84%ED%82%A4:Sitenotice
// $wgReadOnly = '데이터베이스 업그레이드 작업이 진행 중입니다. 작업이 진행되는 동안 사이트 이용이 제한됩니다.';

//// 업로드를 막고싶을때엔 아래 라인 주석 해제하면 됨
// $wgEnableUploads = false;
EOF
}

