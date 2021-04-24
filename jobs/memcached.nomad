job "memcached" {
  datacenters = ["dc1"]

  group "memcached" {
    task "memcached" {
      driver = "docker"

      config {
        image             = "memcached:1.6.9-alpine"
        memory_hard_limit = 200
      }
    }

    network {
      mode = "bridge"

      port "memcached" {
        static = 11211
      }
    }
  }

  reschedule {
    attempts  = 3
    interval  = "24h"
    delay     = "10s"
    unlimited = false
  }

  update {
    auto_revert = true
  }
}
