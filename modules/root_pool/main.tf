terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_profile" "root_pool" {
  for_each = { for i in var.pool_propaties : i.name => i }
  name     = "pool_${each.value.name}"
  driver   = "btrfs"
  config = {
    size   = "${each.value.size}"
    source = "/var/lib/lxd/disks/pool_${each.value.name}.img"
  }
}