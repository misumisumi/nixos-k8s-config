locals {
  optional_instances = merge([
    for i in var.optional_instances : i.instance_name != null ? {
      "${i.instance_name}" = {
        nodes = i.nodes
        rd    = i.instance_RD
    } } : {}
  ]...)
}

terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
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
}

module "pool" {
  source = "./modules/pool"
  pools  = var.pools
}

module "cluster" {
  for_each = merge({
    "etcd" = {
      nodes = var.etcd_instances,
      rd    = var.etcd_RD
    }
    "controlplane" = {
      nodes = var.control_plane_instances,
      rd    = var.control_plane_RD
    }
    "worker" = {
      nodes = var.worker_instances,
      rd    = var.worker_RD
    }
    "loadbalancer" = {
      nodes = var.load_balancer_instances,
      rd    = var.load_balancer_RD
    }
    },
    local.optional_instances
  )

  source = "./modules/node"

  name       = each.key
  nodes      = each.value.nodes
  node_rd    = each.value.rd
  depends_on = [module.network, module.pool, time_sleep.wait_15s]
}
