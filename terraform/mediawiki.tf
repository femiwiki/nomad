resource "nomad_job" "mysql" {
  depends_on = [
    data.nomad_plugin.ebs,
    nomad_volume.mysql,
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

resource "nomad_job" "http" {
  depends_on = [
    data.nomad_plugin.ebs,
    nomad_volume.caddycerts,
  ]

  jobspec = file("../jobs/http.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
  }
}
