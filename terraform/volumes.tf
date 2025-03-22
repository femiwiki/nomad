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
