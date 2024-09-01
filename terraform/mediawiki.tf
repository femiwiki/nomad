locals {
  hcl_vals = {
    test = var.test
  }
}

resource "nomad_job" "mysql_without_ebs" {
  count = var.test ? 1 : 0

  jobspec = file("../jobs/mysql.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars     = local.hcl_vals
  }
}

resource "nomad_job" "mysql" {
  count = !var.test ? 1 : 0

  depends_on = [
    data.nomad_plugin.ebs,
    nomad_csi_volume_registration.mysql,
  ]

  jobspec = file("../jobs/mysql.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars     = local.hcl_vals
  }
}

resource "nomad_job" "memcached" {
  jobspec = file("../jobs/memcached.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
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
    vars     = local.hcl_vals
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
    vars     = local.hcl_vals
  }
}
