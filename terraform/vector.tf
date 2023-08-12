variable "openobserve_password" {
  type      = string
  sensitive = true
}

resource "nomad_job" "vector" {
  detach = false
  # Note: nomad_variable resource is not available before terraform-provider-nomad v2.0.0
  jobspec = templatefile("../jobs/vector.nomad", { openobserve_password = var.openobserve_password })

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}
