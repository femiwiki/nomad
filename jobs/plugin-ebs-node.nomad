# https://learn.hashicorp.com/tutorials/nomad/stateful-workloads-csi-volumes#deploy-the-ebs-plugin
# https://www.nomadproject.io/docs/job-specification/csi_plugin#csi_plugin-examples

job "plugin-ebs-nodes" {
  datacenters = ["dc1"]

  type = "system"

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
        image = "amazon/aws-ebs-csi-driver:v0.10.1"

        args = [
          "node",
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]

        privileged        = true
        memory_hard_limit = 256
      }

      csi_plugin {
        id        = "aws-ebs0"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 20
      }
    }
  }
}
