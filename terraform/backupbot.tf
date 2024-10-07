resource "nomad_job" "backupbot" {
  provider   = nomad.green
  depends_on = [nomad_job.mysql_green]

  detach  = false
  jobspec = file("../jobs/backupbot.nomad")

  hcl2 {
    allow_fs = true
    vars = {
      mysql_password_mediawiki = var.mysql_password_mediawiki
    }
  }
}
