resource "nomad_job" "mysql_green" {
  provider = nomad.green
  depends_on = [
    nomad_csi_volume_registration.mysql_green,
  ]

  jobspec = file("../jobs/mysql.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars = {
      green = true
    }
  }
}

resource "nomad_job" "memcached_green" {
  provider = nomad.green
  jobspec  = file("../jobs/memcached.nomad")
  detach   = false

  hcl2 {
    allow_fs = true
  }
}

resource "nomad_job" "fastcgi_green" {
  provider = nomad.green
  depends_on = [
    nomad_job.memcached_green,
  ]

  jobspec = file("../jobs/fastcgi.nomad")
  detach  = false

  hcl2 {
    allow_fs = true
    vars = {
      mysql_password_mediawiki = var.mysql_password_mediawiki
    }
  }
}

resource "nomad_job" "http_green" {
  provider = nomad.green
  jobspec  = file("../jobs/http.nomad")
  detach   = false

  hcl2 {
    allow_fs = true
  }
}
