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

resource "nomad_job" "plugin_ebs_controller_green" {
  provider = nomad.green
  jobspec  = file("../jobs/plugin-ebs-controller.nomad")

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_job" "plugin_ebs_nodes_green" {
  provider = nomad.green
  jobspec  = file("../jobs/plugin-ebs-nodes.nomad")

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_csi_volume_registration" "mysql_green" {
  provider    = nomad.green
  plugin_id   = "aws-ebs0"
  volume_id   = "mysql_green"
  name        = "mysql_green"
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
  plugin_id   = "aws-ebs0"
  volume_id   = "caddycerts"
  name        = "caddycerts"
  external_id = data.terraform_remote_state.aws.outputs.ebs_caddycerts_id

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_csi_volume_registration" "caddycerts_green" {
  provider    = nomad.green
  plugin_id   = "aws-ebs0"
  volume_id   = "caddycerts_green"
  name        = "caddycerts_green"
  external_id = data.terraform_remote_state.aws.outputs.ebs_caddycerts_green_id

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}
