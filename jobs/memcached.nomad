variable "test" {
  type        = bool
  description = "Uses jobs for the test server.."
  default     = false
}

locals {
  main = !var.test
}

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

      dynamic "port" {
        for_each = var.test ? [] : [{}]
        labels   = ["memcached"]
        content {
          static = 11211
        }
      }
    }

    dynamic "service" {
      for_each = local.main ? [{}] : []
      content {
        provider = "nomad"
        name     = "memcached"
        port     = "memcached"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "1s"
        }
      }
    }

    dynamic "service" {
      for_each = var.test ? [{}] : []
      content {
        name = "memcached"
        port = "11211"

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
  }

  reschedule {
    attempts  = 3
    interval  = "24h"
    delay     = "10s"
    unlimited = false
  }

  update {
    auto_revert  = true
    auto_promote = var.test ? true : false
    # canary count equal to the desired count allows a Nomad job to model blue/green deployments
    canary = var.test ? 1 : 0
  }
}
