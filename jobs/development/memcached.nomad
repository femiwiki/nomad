job "memcached" {
  datacenters = ["dc1"]

  group "memcached" {
    task "memcached" {
      driver = "docker"

      config {
        image             = "memcached:1-alpine"
      }

      resources {
        memory = 60
        memory_max = 240
      }
    }

    network {
      mode = "bridge"

      port "memcached" {
        static = 11211
      }
    }
  }
}
