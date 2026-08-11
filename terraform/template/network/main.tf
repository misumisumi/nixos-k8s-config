terraform {
  required_version = "~> 1.10.0"
  required_providers {
    incus = {
      source  = "registry.opentofu.org/lxc/incus"
      version = "~> 1.0.0"
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

resource "incus_network_peer" "incus_network_peer" {
  for_each = merge([
    for net_key, net_value in var.networks : {
      for peer in net_value.peers :
      "${net_key}-${peer}" => {
        network        = net_key
        peer           = peer
        remote         = net_value.remote
        project        = net_value.project
        target_project = net_value.project
      }
    }
  ]...)
  name           = each.key
  remote         = each.value.remote
  project        = each.value.project
  network        = each.value.network
  target_network = each.value.peer
  target_project = each.value.target_project
}
