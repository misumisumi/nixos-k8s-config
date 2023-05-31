# terraform init
# terraform apply -auto-approve
# terraform destroy -auto-approve


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
resource "null_resource" "label" {
  triggers = {
    name = "labe"
    env  = terraform.workspace
  }
}
module "network" {
  count  = terraform.workspace == "product" ? 0 : 1
  source = "./modules/network"
}


module "node" {
  for_each = {
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
  }

  source = "./modules/node"

  name    = each.key
  nodes   = each.value.nodes
  node_rd = each.value.rd
}