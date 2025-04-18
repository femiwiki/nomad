job "memcached" {
  datacenters = ["dc1"]

  group "memcached" {
    task "memcached" {
      driver = "docker"

      config {
        image = "memcached:1.6.23-alpine"
      }

      resources {
        memory     = 90
        memory_max = 110
      }
    }

    network {
      mode = "bridge"
    }

    service {
      name = "memcached"
      port = "11211"

      check {
        type     = "script"
        task     = "memcached"
        command  = "/usr/bin/nc"
        args     = ["-zv", "localhost", "11211"]
        interval = "10s"
        timeout  = "1s"
      }

      connect {
        sidecar_service {}

        sidecar_task {
          config {
            memory_hard_limit = 40
          }
          resources {
            memory = 30
          }
        }
      }
    }
  }

  reschedule {
    delay     = "10s"
    unlimited = true
  }

  update {
    auto_revert  = true
    auto_promote = true
    canary       = 1
  }
}
