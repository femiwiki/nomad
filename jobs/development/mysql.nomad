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
performance_schema=OFF
max_connections=60 # default to 151

# sorted alphabetically
innodb_buffer_pool_size=64M # default to 128M
innodb_log_file_size=16M # default to 48M
max_binlog_cache_size=32M # default to 16 exbibytes
max_binlog_stmt_cache_size=32M # default to 16 exbibytes
max_heap_table_size=8M # default to 16M
myisam_mmap_size=64M # default to 16 exbibytes
parser_max_mem_size=256M # default to 16 exbibytes
table_open_cache=300 # default to 4000
temptable_max_mmap=64M # default to 1G
temptable_max_ram=64M # default to 1G
tmp_table_size=8M # defaults to 16M
EOF
        destination = "local/my.cnf"
      }

      config {
        image   = "mysql/mysql-server:8.0"
        volumes = ["local/my.cnf:/etc/mysql/my.cnf"]

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
        memory     = 400
        memory_max = 700
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
