terraform {
  required_version = "~> 1.8.5"
  required_providers {
    incus = {
      source  = "registry.opentofu.org/lxc/incus"
      version = "~> 0.1.4"
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

resource "incus_network" "incus_network" {
  for_each = var.networks
  name     = each.key
  remote   = each.value.remote
  project  = each.value.project
  config   = each.value.config
}

