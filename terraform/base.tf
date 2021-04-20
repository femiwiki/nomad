variable "nomad_addr" {
  type = string
}

variable "nomad_token" {
  type      = string
  sensitive = true
}

terraform {
  required_version = "~> 0.15.0"

  backend "remote" {
    organization = "femiwiki"

    workspaces {
      name = "nomad"
    }
  }

  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 1.4"
    }
  }
}

provider "nomad" {
  address   = var.nomad_addr
  secret_id = var.nomad_token
}
