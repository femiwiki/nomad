job "aws_mountpoint_s3_csi_driver" {
  datacenters = ["dc1"]

  # only one plugin of a given type and ID should be deployed on
  # any given client node
  constraint {
    operator = "distinct_hosts"
    value    = true
  }

  group "nodes" {
    task "plugin" {
      driver = "docker"

      config {
        image = "public.ecr.aws/mountpoint-s3-csi-driver/aws-mountpoint-s3-csi-driver:v1.9.0"

        args = [
          "--endpoint=unix:/csi/csi.sock",
          "--v=5",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "aws-s3"
        type      = "monolith"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 20
      }

      env {
        PTMX_PATH     = "/host/dev/ptmx"
        CSI_NODE_NAME = node.unique.id
      }
    }

    restart {
      attempts = 3
      interval = "24h"
      delay    = "10s"
    }
  }

  reschedule {
    delay     = "10s"
    unlimited = true
  }

  update {
    auto_revert = true
  }
}
