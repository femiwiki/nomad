job "mysql" {
  datacenters = ["dc1"]

  group "mysql" {
    task "mysql" {
      driver = "docker"

      template {
        data        = <<EOF
[mysqld]
skip-host-cache
skip-name-resolve
default_authentication_plugin=mysql_native_password
EOF
        destination = "local/custom.cnf"
      }

      template {
        data        = <<EOF
[mysqld]
max_connections=20
EOF
        destination = "local/my.cnf"
      }

      config {
        image             = "mysql/mysql-server:8.0"
        memory_hard_limit = 1000
        volumes = [
          "local/custom.cnf:/etc/mysql/conf.d/custom.cnf",
          "local/my.cnf:/etc/mysql/my.cnf",
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
