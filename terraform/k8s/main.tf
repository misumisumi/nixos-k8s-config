locals {
  compornents = merge([
    for i in var.compornents : {
      "${i.remote}" = {
        instances = i.instances
        profiles  = i.profiles
    } }
  ]...)
}

terraform {
  required_providers {
    incus = {
      source  = "registry.terraform.io/lxc/incus"
      version = "~> 0.0.2"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  dynamic "remote" {
    for_each = var.remote_hosts
    content {
      name    = incus_remote.value.name
      address = incus_remote.value.address
      scheme  = "https"
    }
  }
}

# Only use making env label for outputing show.json to use from colmena
resource "terraform_data" "workspace" {
  input = terraform.workspace
}

module "instances" {
  for_each = local.compornents
  source   = "../modules/instance"

  # tag                  = each.key
  instances = each.value.instances
  profiles  = each.value.profiles
}

