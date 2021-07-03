job "restbase" {
  datacenters = ["dc1"]

  group "restbase" {
    task "restbase" {
      driver = "docker"

      config {
        image = "ghcr.io/femiwiki/restbase:latest"
        ports = ["restbase"]
      }

      resources {
        memory     = 100
        memory_max = 400
      }

      env {
        MEDIAWIKI_APIS_DOMAIN = "localhost"
        MEDIAWIKI_APIS_URI    = "http://${NOMAD_UPSTREAM_ADDR_http}/api.php"
        PARSOID_URI           = "http://${NOMAD_UPSTREAM_ADDR_http}/rest.php"
        MATHOID_URI           = "http://${NOMAD_UPSTREAM_ADDR_mathoid}"
        # Amazon EC2-t type small instances has two vCPUs
        RESTBASE_NUM_WORKERS = "2"
      }
    }

    network {
      mode = "bridge"

      port "restbase" {
        to = 7231
      }
    }

    service {
      name         = "restbase"
      port         = "restbase"
      address_mode = "alloc"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "http"
              local_bind_port  = 8080
            }

            upstreams {
              destination_name = "mathoid"
              local_bind_port  = 10044
            }
          }
        }
      }
    }
  }
}
