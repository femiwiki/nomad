job "restbase" {
  datacenters = ["dc1"]

  group "restbase" {
    task "restbase" {
      driver = "docker"

      config {
        image = "ghcr.io/femiwiki/restbase:latest"
        ports = ["restbase"]
      }

      env {
        # Amazon EC2-t type small instances has two vCPUs
        RESTBASE_NUM_WORKERS  = "2"
        MEDIAWIKI_APIS_DOMAIN = "localhost"
        MEDIAWIKI_APIS_URI    = "http://${NOMAD_UPSTREAM_ADDR_http}/api.php"
        PARSOID_URI           = "http://${NOMAD_UPSTREAM_ADDR_parsoid}"
        MATHOID_URI           = "http://${NOMAD_UPSTREAM_ADDR_mathoid}"
      }
    }

    network {
      mode = "bridge"

      port "restbase" {
        to = 7231
      }
    }

    service {
      name = "restbase"
      port = "restbase"
      address_mode = "alloc"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "http"
              local_bind_port  = 8080
            }

            upstreams {
              destination_name = "parsoid"
              local_bind_port  = 8000
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
