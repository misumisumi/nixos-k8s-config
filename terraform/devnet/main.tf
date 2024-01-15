locals {
  networks = merge([
    for i in var.networks : {
      "${i.name}" = {
        ipv4_address = i.ipv4_address
        ipv6_address = i.ipv6_address
        nat          = i.nat
    } }
  ]...)
}

terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 1.10.4"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  dynamic "lxd_remote" {
    for_each = var.remote_hosts
    content {
      name    = lxd_remote.value.name
      address = lxd_remote.value.address
      scheme  = "https"
    }
  }
}

# Only use making env label for outputing show.json to use from colmena
resource "terraform_data" "workspace" {
  input = terraform.workspace
}

resource "time_sleep" "wait_15s" {
  depends_on       = [module.networks]
  create_duration  = "15s"
  destroy_duration = "15s"
}

module "networks" {
  source   = "../modules/network"
  for_each = local.networks

  name         = each.key
  ipv4_address = each.value.ipv4_address
  ipv6_address = each.value.ipv6_address
  nat          = each.value.nat
}

