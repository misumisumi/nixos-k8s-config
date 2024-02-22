terraform {
  required_providers {
    incus = {
      source  = "registry.terraform.io/lxc/incus"
      version = "~> 0.0.2"
    }
  }
}

resource "incus_storage_pool" "pool" {
  for_each = { for i in var.pools : i.name => i }
  remote   = var.remote
  project  = var.project
  name     = each.value.name
  driver   = lookup(each.value, "driver", "btrfs")
  config   = each.value.config
}
