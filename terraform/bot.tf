resource "nomad_job" "backupbot" {
  depends_on = [
    nomad_volume.secrets,
    nomad_job.mysql
  ]

  detach  = false
  jobspec = file("../jobs/backupbot.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}
