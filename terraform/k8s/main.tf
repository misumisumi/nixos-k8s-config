terraform {
  required_providers {
    incus = {
      source  = "registry.opentofu.org/lxc/incus"
      version = "~> 0.1.4"
    }
    random = {
      source  = "registry.opentofu.org/hashicorp/random"
      version = "~> 3.6.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.1.0"
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

# Only use making env label for outputting show.json to use from colmena
resource "terraform_data" "workspace" {
  input = terraform.workspace
}

module "instances" {
  for_each = { for i in var.compornents : i.remote => i }
  source   = "../modules/instance"

  remote    = each.value.remote
  instances = each.value.instances
  profiles  = each.value.profiles
}

