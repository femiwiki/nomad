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

resource "nomad_job" "memcached_green" {
  provider = nomad.green
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

resource "nomad_job" "fastcgi_green" {
  provider = nomad.green
  depends_on = [
    nomad_job.memcached,
  ]

  jobspec = file("../jobs/fastcgi.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars = {
      test                     = true
      main_nomad_private_ip    = data.terraform_remote_state.aws.outputs.nomad_private_ip
      mysql_password_mediawiki = var.mysql_password_mediawiki
      test_nomad_public_ip     = data.terraform_remote_state.aws.outputs.nomad_green_public_ip
      test_include_mysql       = false
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

resource "nomad_job" "http_green" {
  provider = nomad.green
  # TODO Replace EBS CSI with S3 CSI or something
  depends_on = [
    data.nomad_plugin.ebs_green,
    nomad_csi_volume_registration.caddycerts_green,
  ]

  jobspec = file("../jobs/http.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars = {
      test = true
    }
  }
}
