job "mathoid" {
  datacenters = ["dc1"]

  group "mathoid" {
    task "mathoid" {
      driver = "docker"

      config {
        image = "ghcr.io/femiwiki/mathoid:latest"
      }

      resources {
        memory = 150
        memory_max = 600
      }

      env {
        # Amazon EC2-t type small instances has two vCPUs
        MATHOID_NUM_WORKERS = "2"
      }
    }

    network {
      mode = "bridge"

      port "mathoid" {
        static = 10044
      }
    }
  }
}
