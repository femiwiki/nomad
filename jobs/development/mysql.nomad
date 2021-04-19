job "mysql" {
  datacenters = ["dc1"]

  group "mysql" {
    task "mysql" {
      driver = "docker"

      config {
        image             = "mysql/mysql-server:8.0"
        args              = ["--default-authentication-plugin=mysql_native_password"]
        memory_hard_limit = 1000
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
