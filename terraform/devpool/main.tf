terraform {
  required_providers {
    incus = {
      source  = "registry.opentofu.org/lxc/incus"
      version = "~> 0.1.1"
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

module "pools" {
  for_each = { for i in var.compornents : i.remote => i }
  source   = "../modules/pool"

  remote  = each.value.remote
  project = each.value.project
  pools   = each.value.pools
}

module "volumes" {
  for_each = { for i in var.compornents : i.remote => i }
  source   = "../modules/volume"

  remote  = each.value.remote
  project = each.value.project
  volumes = each.value.volumes

  depends_on = [module.pools]
}
