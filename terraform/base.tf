variable "nomad_token" {
  type      = string
  sensitive = true
}

variable "nomad_green_token" {
  type      = string
  sensitive = true
}

variable "consul_green_token" {
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
      version = "~> 2.1"
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
  address   = "http://${data.terraform_remote_state.aws.outputs.nomad_blue_public_ip}:4646"
  secret_id = var.nomad_token
  # Should be specified explicitly because of the bug https://github.com/femiwiki/nomad/issues/99
  region = "global"
}

provider "nomad" {
  alias     = "green"
  address   = "http://${data.terraform_remote_state.aws.outputs.nomad_green_public_ip}:4646"
  secret_id = var.nomad_green_token
  region    = "global"
}
