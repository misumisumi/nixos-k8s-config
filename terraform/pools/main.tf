terraform {
  required_providers {
    incus = {
      source  = "registry.terraform.io/lxc/incus"
      version = "~> 0.0.2"
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

resource "incus_storage_pool" "pools" {
  for_each = var.pools
  name     = each.key
  driver   = each.value.driver
  config = each.value.config
}
