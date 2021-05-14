job "mysql" {
  datacenters = ["dc1"]

  group "mysql" {
    task "mysql" {
      driver = "docker"

      template {
        data        = <<EOF
[mysqld]
default_authentication_plugin=mysql_native_password
datadir=/srv/mysql
max_connections=20
temptable_max_ram=64M
temptable_max_mmap=64M
max_binlog_cache_size=32K
max_binlog_stmt_cache_size=32K
myisam_mmap_size=64M
parser_max_mem_size=64M
EOF
        destination = "local/my.cnf"
      }

      config {
        image             = "mysql/mysql-server:8.0"
        memory_hard_limit = 1000
        volumes           = ["local/my.cnf:/etc/mysql/my.cnf"]

        mounts = [
          {
            type     = "volume"
            source   = "mysql"
            target   = "/srv/mysql"
            readonly = false
          },
        ]
      }

      resources {
        memory = 500
      }

      env {
        MYSQL_ROOT_PASSWORD = "localfemiwikipassword"
        MYSQL_DATABASE      = "femiwiki"
        MYSQL_USER          = "DB_USERNAME" // secrets.php.example에 적힌 기본값
        MYSQL_PASSWORD      = "DB_PASSWORD" // secrets.php.example에 적힌 기본값
      }
    }

    network {
      mode = "bridge"

      port "mysql" {
        static = 3306
      }
    }
  }
}
