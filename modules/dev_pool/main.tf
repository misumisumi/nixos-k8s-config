terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_storage_pool" "dev_pool" {
  for_each = { for i in var.pools : i.name => i }
  name     = each.value.name
  driver   = "btrfs"
  config = {
    size = each.value.size
  }
}
