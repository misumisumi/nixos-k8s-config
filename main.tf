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
    "etcd" : {
      "count" : var.etcd_instances,
      "cpu" : 2,
      "memory" : "2GB",
    }
    "controlplane" : {
      "count" : var.control_plane_instances,
      "cpu" : 2,
      "memory" : "2GB",
    }
    "worker" : {
      "count" : var.worker_instances,
      "cpu" : 2,
      "memory" : "2GB",
    }
    "loadbalancer" : {
      "count" : var.load_balancer_instances,
      "cpu" : 2,
      "memory" : "2GB",
    }
  }

  source = "./modules/node"

  name         = each.key
  num_replicas = each.value.count
  memory       = each.value.memory
  cpu          = each.value.cpu
}
