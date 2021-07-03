job "memcached" {
  datacenters = ["dc1"]

  group "memcached" {
    task "memcached" {
      driver = "docker"

      config {
        image = "memcached:1-alpine"
        ports = ["memcached"]
      }

      resources {
        memory = 100
      }
    }

    network {
      mode = "bridge"

      port "memcached" {
        to = 11211
      }
    }

    service {
      name         = "memcached"
      port         = "memcached"
      address_mode = "alloc"

      connect {
        sidecar_service {}
      }
    }
  }
}
