resource "nomad_job" "mysql" {
  depends_on = [
    data.nomad_plugin.ebs,
    nomad_csi_volume_registration.mysql,
  ]

  jobspec = file("../jobs/mysql.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_job" "memcached" {
  jobspec = file("../jobs/memcached.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_job" "test_memcached" {
  provider = nomad.test
  count    = 0
  jobspec  = file("../jobs/memcached.nomad")
  detach   = false

  hcl2 {
    allow_fs = true
    vars = {
      test = true
    }
  }
}

resource "nomad_job" "fastcgi" {
  depends_on = [
    nomad_job.mysql,
    nomad_job.memcached,
  ]

  jobspec = file("../jobs/fastcgi.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_job" "test_fastcgi" {
  provider = nomad.test
  count    = 0
  depends_on = [
    nomad_job.memcached,
  ]

  jobspec = file("../jobs/fastcgi.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars = {
      test                     = true
      main_nomad_addr          = data.terraform_remote_state.aws.outputs.nomad_addr
      mysql_password_mediawiki = var.mysql_password_mediawiki
      test_nomad_addr          = data.terraform_remote_state.aws.outputs.test_nomad_addr
    }
  }
}

resource "nomad_job" "http" {
  depends_on = [
    data.nomad_plugin.ebs,
    nomad_csi_volume_registration.caddycerts,
  ]

  jobspec = file("../jobs/http.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_job" "test_http" {
  provider = nomad.test
  # TODO Replace EBS CSI with S3 CSI or something
  count = 0
  # depends_on = [
  #   data.nomad_plugin.ebs,
  #   nomad_csi_volume_registration.caddycerts,
  # ]

  jobspec = file("../jobs/http.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars = {
      test            = true
      test_nomad_addr = data.terraform_remote_state.aws.outputs.test_nomad_addr
    }
  }
}
