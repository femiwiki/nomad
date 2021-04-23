job "mathoid" {
  datacenters = ["dc1"]

  group "mathoid" {
    task "mathoid" {
      driver = "docker"

      config {
        image             = "ghcr.io/femiwiki/mathoid:2021-04-17T11-11-4e1427b4"
        memory_hard_limit = 300
      }

      resources {
        memory = 170
      }

      env {
        MATHOID_NUM_WORKERS = "0"
      }

    }

    network {
      mode = "bridge"

      port "mathoid" {
        static = 10044
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
