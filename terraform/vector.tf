variable "openobserve_password" {
  type      = string
  sensitive = true
}

resource "nomad_job" "vector" {
  count  = 0
  detach = false
  # Note: nomad_variable resource is not available before terraform-provider-nomad v2.0.0
  jobspec = replace(file("../jobs/vector.nomad"), "OPENOBSERVE_PASSWORD", var.openobserve_password)

  hcl2 {
    enabled  = true
    allow_fs = true
  }
}
