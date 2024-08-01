job "fastcgi" {
  datacenters = ["dc1"]

  group "fastcgi" {
    # Init Task Lifecycle
    # Reference: https://www.nomadproject.io/docs/job-specification/lifecycle#init-task-pattern
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

    task "fastcgi" {
      driver = "docker"

      artifact {
        source      = "s3::https://femiwiki-secrets.s3-ap-northeast-1.amazonaws.com/secrets.php"
        destination = "secrets/secrets.php"
        mode        = "file"
      }

      artifact {
        source      = "s3::https://femiwiki-secrets.s3-ap-northeast-1.amazonaws.com/analytics-credentials-file.json"
        destination = "secrets/analytics-credentials-file.json"
        mode        = "file"
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/php/opcache-recommended.ini"
        destination = "local/opcache-recommended.ini"
        mode        = "file"
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/php/php.ini"
        destination = "local/php.ini"
        mode        = "file"

        options { checksum = "md5:80449c56193c217c38f4badfb6134410" }
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/php/php-fpm.conf"
        destination = "local/php-fpm.conf"
        mode        = "file"

        options { checksum = "md5:8060e82333648317f1f160779d31f197" }
      }

      artifact {
        source      = "https://github.com/femiwiki/nomad/raw/main/php/www.conf"
        destination = "local/www.conf"
        mode        = "file"

        options { checksum = "md5:8ce9afeeee1ae1ff893b58be8dc7c3ec" }
      }

      template {
        data        = var.hotfix
        destination = "local/Hotfix.php"
        change_mode = "noop"
      }

      template {
        data        = var.postrun
        destination = "local/postrun"
        change_mode = "noop"
      }

      template {
        data        = var.postrun
        destination = "local/prerun"
        change_mode = "noop"
      }

      config {
        image = "ghcr.io/femiwiki/femiwiki:2024-06-30T07-56-ff4502c2"

        volumes = [
          "local/opcache-recommended.ini:/usr/local/etc/php/conf.d/opcache-recommended.ini",
          "local/php.ini:/usr/local/etc/php/php.ini",
          "local/php-fpm.conf:/usr/local/etc/php-fpm.conf",
          "local/www.conf:/usr/local/etc/php-fpm.d/www.conf",
          "secrets/secrets.php:/a/secret.php",
          "secrets/analytics-credentials-file.json:/a/analytics-credentials-file.json",
          # Overwrite the default Hotfix.php provided by femiwiki/mediawiki
          "local/Hotfix.php:/a/Hotfix.php",
          "local/postrun:/usr/local/bin/postrun",
          "local/prerun:/usr/local/bin/prerun",
        ]

        mounts = [
          {
            type     = "volume"
            target   = "/srv/femiwiki.com/sitemap"
            source   = "sitemap"
            readonly = false
          },
          {
            type     = "volume"
            target   = "/tmp/cache"
            source   = "l18n_cache"
            readonly = false
          },
        ]

        cpu_hard_limit = true

        network_mode = "host"
      }

      resources {
        cpu        = 3000
        memory     = 400
        memory_max = 800
      }

      env {
        NOMAD_UPSTREAM_ADDR_http      = "127.0.0.1:80"
        NOMAD_UPSTREAM_ADDR_memcached = "127.0.0.1:11211"
        MEDIAWIKI_SKIP_INSTALL        = "1"
        MEDIAWIKI_SKIP_IMPORT_SITES   = "1"
        MEDIAWIKI_SKIP_UPDATE         = "1"
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
/**
 * Use this file for hotfixes
 *
 * @file
 */

$wgScribuntoEngineConf['luastandalone']['cpuLimit'] = 1;
$wgScribuntoEngineConf['luastandalone']['memoryLimit'] = 10485760;

$wgMWLoggerDefaultSpi = [ 'class' => 'MediaWiki\\Logger\\LegacySpi' ]; # default
# https://github.com/femiwiki/UnifiedExtensionForFemiwiki/issues/147
$wgUnifiedExtensionForFemiwikiBlockByEmail = false;

// Maintenance
// 점검이 끝나면 아래 라인 주석처리한 뒤, 아래 문서 내용을 비우면 됨
// https://femiwiki.com/w/%EB%AF%B8%EB%94%94%EC%96%B4%EC%9C%84%ED%82%A4:Sitenotice
// $wgReadOnly = '데이터베이스 업그레이드 작업이 진행 중입니다. 작업이 진행되는 동안 사이트 이용이 제한됩니다.';

// 업로드를 막고싶을때엔 아래 라인 주석 해제하면 됨
// $wgEnableUploads = false;
EOF
}

variable "postrun" {
  type    = string
  default = <<EOF
#!/bin/bash
set -euo pipefail; IFS=$'\n\t'

EOF
}

variable "pretrun" {
  type    = string
  default = <<EOF
#!/bin/bash
set -euo pipefail; IFS=$'\n\t'

EOF
}

