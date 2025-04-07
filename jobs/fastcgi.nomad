variable "mysql_password_mediawiki" {
  type    = string
  default = ""
}

job "fastcgi" {
  datacenters = ["dc1"]

  group "fastcgi" {
    count = 2

    task "await_mysql" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      driver = "docker"
      config {
        image        = "busybox:1.28"
        command      = "sh"
        network_mode = "host"
        args = [
          "-c",
          "echo -n 'Waiting for service'; until nslookup mysql.service.consul 127.0.0.1:8600 2>&1 >/dev/null; do echo '.'; sleep 2; done"
        ]
      }

      resources {
        cpu    = 100
        memory = 100
      }
    }

    task "await_memcached" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      driver = "docker"
      config {
        image        = "busybox:1.28"
        command      = "sh"
        network_mode = "host"
        args = [
          "-c",
          "echo -n 'Waiting for service'; until nslookup memcached.service.consul 127.0.0.1:8600 2>&1 >/dev/null; do echo '.'; sleep 2; done",
        ]
      }

      resources {
        cpu    = 100
        memory = 100
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

        options { checksum = "md5:fa11e91ebb96995b117b9a7408c3f315" }
      }

      artifact {
        source      = "https://github.com/wikimedia/operations-docker-images-production-images/raw/ad68c7cb62e4e01436ab3a34fb961fe8034c2cce/images/php/common/fpm/live-test/AdoyFastCgiClient.php"
        destination = "local/AdoyFastCgiClient.php"
        mode        = "file"
      }

      artifact {
        source      = "https://github.com/wikimedia/operations-docker-images-production-images/raw/ad68c7cb62e4e01436ab3a34fb961fe8034c2cce/images/php/common/fpm/live-test/fcgi-probe.php"
        destination = "local/fcgi-probe.php"
        mode        = "file"
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
        image = "ghcr.io/femiwiki/femiwiki:2025-04-07T12-44-7295848d"

        volumes = [
          "local/opcache-recommended.ini:/usr/local/etc/php/conf.d/opcache-recommended.ini",
          "local/php.ini:/usr/local/etc/php/php.ini",
          "local/php-fpm.conf:/usr/local/etc/php-fpm.conf",
          "local/www.conf:/usr/local/etc/php-fpm.d/www.conf",
          "local/AdoyFastCgiClient.php:/srv/fcgi-check/AdoyFastCgiClient.php",
          "local/fcgi-probe.php:/srv/fcgi-check/fcgi-probe.php",
          "secrets/secrets.php:/a/secrets.php",
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
      }

      resources {
        cpu        = 3000
        memory     = 400
        memory_max = 400
      }

      env {
        # Used by fcgi-probe.php
        FCGI_URL = "127.0.0.1:9000"

        MEDIAWIKI_SKIP_INSTALL      = "1"
        MEDIAWIKI_SKIP_IMPORT_SITES = "1"
        MEDIAWIKI_SKIP_UPDATE       = "1"
        WG_DB_SERVER                = NOMAD_UPSTREAM_ADDR_mysql
        WG_DB_USER                  = "mediawiki"
        WG_DB_PASSWORD              = var.mysql_password_mediawiki
      }
    }

    service {
      name = "fastcgi"
      port = "9000"
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
          }
        }
        sidecar_task {
          config {
            memory_hard_limit = 70
          }
          resources {
            memory = 50
          }
        }
      }
      check {
        # readiness
        type     = "script"
        task     = "fastcgi"
        command  = "/usr/local/bin/php"
        args     = ["/srv/fcgi-check/fcgi-probe.php"]
        interval = "10s"
        timeout  = "1s"
      }
    }

    network {
      mode = "bridge"
    }
  }

  update {
    auto_revert       = true
    auto_promote      = true
    canary            = 1
    progress_deadline = "1h"
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

$wgAutoConfirmAge = 3600;
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

test -s /a/secrets.php
test -s /a/LocalSettings.php
EOF
}
