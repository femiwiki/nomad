# https://learn.hashicorp.com/tutorials/nomad/load-balancing-traefik
job "lb" {
  datacenters = ["dc1"]

  group "lb" {
    count = 1

    network {
      port "http" {
        static = 80
      }

      port "api" {
        static = 8081
      }
    }

    service {
      name = "lb"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "lb" {
      driver = "docker"

      config {
        image             = "traefik:v2.4.8"
        network_mode      = "host"
        memory_hard_limit = 500
        ports             = ["http", "api"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
  [entryPoints.http]
  address = ":80"
  [entryPoints.traefik]
  address = ":8081"

[api]
  dashboard = true
  insecure  = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
  exposedByDefault = false

  [providers.consulCatalog.endpoint]
    address = "127.0.0.1:8500"
    scheme  = "http"
EOF

        destination = "local/traefik.toml"
      }

      resources {
        memory = 128
      }
    }
  }
}
