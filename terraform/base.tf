variable "nomad_token" {
  type      = string
  sensitive = true
}

variable "nomad_token_consul_test" {
  type      = string
  sensitive = true
}

terraform {
  required_version = "~> 1.0"

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

data "terraform_remote_state" "aws" {
  backend = "remote"
  config = {
    organization = "femiwiki"
    workspaces = {
      name = "aws"
    }
  }
}

provider "nomad" {
  address   = data.terraform_remote_state.aws.outputs.nomad_addr
  secret_id = var.nomad_token
}

# provider "nomad" {
#   alias     = "consul_test"
#   address   = data.terraform_remote_state.aws.outputs.nomad_addr_consul_test
#   secret_id = var.nomad_token_consul_test
# }
