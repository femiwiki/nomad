job "restbase" {
  datacenters = ["dc1"]

  group "restbase" {
    task "restbase" {
      driver = "docker"

      config {
        image             = "ghcr.io/femiwiki/restbase:latest"
        network_mode      = "host"
        memory_hard_limit = 400
      }

      resources {
        memory = 100
      }

      env {
        MEDIAWIKI_APIS_DOMAIN = "localhost"
        MEDIAWIKI_APIS_URI    = "http://127.0.0.1:8080/api.php"
        PARSOID_URI           = "http://127.0.0.1:8000/rest.php"
        MATHOID_URI           = "http://127.0.0.1:10044"
        # Amazon EC2-t type small instances has two vCPUs
        RESTBASE_NUM_WORKERS = "2"
      }
    }
  }
}
