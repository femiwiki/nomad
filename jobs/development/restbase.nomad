job "restbase" {
  datacenters = ["dc1"]

  group "restbase" {
    task "restbase" {
      driver = "docker"

      config {
        image             = "ghcr.io/femiwiki/restbase:latest"
        network_mode      = "host"
      }

      resources {
        memory     = 100
        memory_max = 400
      }

      env {
        MEDIAWIKI_APIS_DOMAIN = "localhost"
        MEDIAWIKI_APIS_URI    = "http://127.0.0.1:8080/api.php"
        PARSOID_URI           = "http://127.0.0.1:8000/rest.php"
        # Amazon EC2-t type small instances has two vCPUs
        RESTBASE_NUM_WORKERS = "2"
      }
    }
  }
}
