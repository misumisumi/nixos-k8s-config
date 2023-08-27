locals {
  compornents = merge([
    for i in var.compornents : i.tag != null ? {
      "${i.tag}" = {
        nodes       = i.nodes
        node_config = i.node_config
    } } : {}
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
  count  = terraform.workspace == "product" ? 0 : 1
  source = "./modules/network"

  name         = "k8sbr0"
  ipv4_address = "10.150.10.1/24"
}

module "pool" {
  source = "./modules/pool"
  pools  = var.pools
}

module "cluster" {
  for_each = local.compornents
  source   = "./modules/node"

  nodes       = each.value.nodes
  node_config = each.value.node_config
  depends_on  = [module.network, module.pool, time_sleep.wait_15s]
}
