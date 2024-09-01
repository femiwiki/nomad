resource "nomad_job" "backupbot" {
  count = !var.test ? 1 : 0

  depends_on = [nomad_job.mysql]

  detach  = false
  jobspec = file("../jobs/backupbot.nomad")

  hcl2 {
    allow_fs = true
  }
}
