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

module "node" {
  for_each = {
    etcd = {
      count      = var.etcd_instances,
      cpu        = tonumber(var.etcd_RD.cpu)
      memory     = var.etcd_RD.memory
      nic_parent = var.etcd_RD.nic_parent
    }
    "controlplane" = {
      count      = var.control_plane_instances,
      cpu        = tonumber(var.control_plane_RD.cpu)
      memory     = var.control_plane_RD.memory
      nic_parent = var.control_plane_RD.nic_parent
    }
    worker = {
      count      = var.worker_instances,
      cpu        = tonumber(var.worker_RD.cpu)
      memory     = var.worker_RD.memory
      nic_parent = var.worker_RD.nic_parent
    }
    "loadbalancer" = {
      count      = var.load_balancer_instances,
      cpu        = tonumber(var.load_balancer_RD.cpu)
      memory     = var.load_balancer_RD.memory
      nic_parent = var.load_balancer_RD.nic_parent
    }
  }

  source = "./modules/node"

  name       = each.key
  node_names = each.value.count
  memory     = each.value.memory
  cpu        = each.value.cpu
  nic_parent = each.value.nic_parent
}