locals {
  compornents = merge([
    for i in var.compornents : {
      "${i.tag}" = {
        instances       = i.instances
        instance_config = i.instance_config
    } }
  ]...)
}

terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 1.10.2"
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
  depends_on       = [module.network]
  create_duration  = "15s"
  destroy_duration = "15s"
}

module "network" {
  count  = terraform.workspace == "product" || var.network == null ? 0 : 1
  source = "../modules/network"

  name         = var.network.name
  ipv4_address = var.network.ipv4_address
}

module "pool" {
  source = "../modules/pool"
  pools  = var.pools
}

module "instances" {
  for_each = local.compornents
  source   = "../modules/instance"

  tag             = each.key
  instances       = each.value.instances
  instance_config = each.value.instance_config
  depends_on      = [module.network, module.pool, time_sleep.wait_15s]
}
