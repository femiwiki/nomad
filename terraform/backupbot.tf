resource "nomad_job" "backupbot" {
  count      = 0
  depends_on = [nomad_job.mysql_green]

  detach  = false
  jobspec = file("../jobs/backupbot.nomad")

  hcl2 {
    allow_fs = true
  }
}
