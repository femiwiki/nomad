resource "nomad_job" "plugin-ebs-controller" {
  jobspec = file("../jobs/plugin-ebs-controller.nomad")

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_job" "plugin-ebs-nodes" {
  jobspec = file("../jobs/plugin-ebs-nodes.nomad")

  hcl2 {
    allow_fs = true
  }
}

data "nomad_plugin" "ebs" {
  plugin_id        = "aws-ebs0"
  wait_for_healthy = true
}

import {
  id = "mysql@default"
  to = nomad_csi_volume_registration.mysql
}
resource "nomad_csi_volume_registration" "mysql" {
  depends_on  = [data.nomad_plugin.ebs]
  plugin_id   = "aws-ebs0"
  volume_id   = "mysql"
  name        = "mysql"
  external_id = data.terraform_remote_state.aws.outputs.ebs_mysql_id

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

import {
  id = "caddycerts@default"
  to = nomad_csi_volume_registration.caddycerts
}
resource "nomad_csi_volume_registration" "caddycerts" {
  depends_on  = [data.nomad_plugin.ebs]
  plugin_id   = "aws-ebs0"
  volume_id   = "caddycerts"
  name        = "caddycerts"
  external_id = data.terraform_remote_state.aws.outputs.ebs_caddycerts_id

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}
