job "memcached" {
  datacenters = ["dc1"]

  group "memcached" {
    task "memcached" {
      driver = "docker"

      config {
        image = "memcached:1.6.23-alpine"
      }

      resources {
        memory = 100
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
            memory_hard_limit = 300
          }
          resources {
            memory = 20
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
    # canary count equal to the desired count allows a Nomad job to model blue/green deployments
    canary = 1
  }
}
