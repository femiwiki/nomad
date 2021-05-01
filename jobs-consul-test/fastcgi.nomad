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
            "while [ -z \"$(dig +noall +answer @localhost mysql.service.dc1.consul)\" ]; do sleep 1; done",
            "while [ -z \"$(dig +noall +answer @localhost memcached.service.dc1.consul\)" ]; do sleep 1; done"
          ])
        ]
      }
    }

    task "fastcgi" {
      driver = "docker"

      artifact {
        # During test period
        # source      = "s3::https://femiwiki-secrets.s3-ap-northeast-1.amazonaws.com/secrets.php"
        source      = "https://raw.githubusercontent.com/femiwiki/docker-mediawiki/main/configs/secret.php.example"
        destination = "secrets/secrets.php"
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

        options { checksum = "md5:bf4d0d65b0e696c098213b75cee5d80a" }
      }

      template {
        data        = var.hotfix
        destination = "local/Hotfix.php"
        change_mode = "noop"
      }

      config {
        image = "ghcr.io/femiwiki/mediawiki:2021-04-25T05-29-a73ed5f4"

        volumes = [
          "local/opcache-recommended.ini:/usr/local/etc/php/conf.d/opcache-recommended.ini",
          "local/php.ini:/usr/local/etc/php/php.ini",
          "local/php-fpm.conf:/usr/local/etc/php-fpm.conf",
          "local/www.conf:/usr/local/etc/php-fpm.d/www.conf",
          "secrets/secrets.php:/a/secret.php",
          # Overwrite the default Hotfix.php provided by femiwiki/mediawiki
          "local/Hotfix.php:/a/Hotfix.php",
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
          }
        ]

        memory_hard_limit = 800
      }

      resources {
        memory = 400
      }

      env {
        NOMAD_UPSTREAM_ADDR_http      = "127.0.0.1:80"
        NOMAD_UPSTREAM_ADDR_memcached = "127.0.0.1:11211"
        NOMAD_UPSTREAM_ADDR_parsoid   = "127.0.0.1:8000"
        NOMAD_UPSTREAM_ADDR_restbase  = "127.0.0.1:7231"
        NOMAD_UPSTREAM_ADDR_mathoid   = "127.0.0.1:10044"
        MEDIAWIKI_SKIP_INSTALL        = "1"
        MEDIAWIKI_SKIP_UPDATE         = "1"
        MEDIAWIKI_SKIP_IMPORT_SITES   = "1"
      }
    }

    network {
      mode = "bridge"
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

            upstreams {
              destination_name = "parsoid"
              local_bind_port  = 8000
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

        sidecar_task {
          config {
            memory_hard_limit = 500
          }
          resources {
            memory = 100
          }
        }
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
// Use this file for hotfixes

// Maintenance
//// 점검이 끝나면 아래 라인 주석처리한 뒤, 아래 문서 내용을 비우면 됨
//// https://femiwiki.com/w/%EB%AF%B8%EB%94%94%EC%96%B4%EC%9C%84%ED%82%A4:Sitenotice
// $wgReadOnly = '데이터베이스 업그레이드 작업이 진행 중입니다. 작업이 진행되는 동안 사이트 이용이 제한됩니다.';

//// 업로드를 막고싶을때엔 아래 라인 주석 해제하면 됨
// $wgEnableUploads = false;
EOF
}

