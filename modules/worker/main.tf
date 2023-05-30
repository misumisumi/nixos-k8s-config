terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}
resource "lxd_profile" "pool_root" {
  name   = "pool_root_${var.name}"
  driver = "btrfs"
  config = {
    size   = "8GiB"
    source = "/var/lib/lxd/disks/pool_${var.name}.img"
  }
}
resource "lxd_storage_pool" "pool_ceph" {
  name = "pool_ceph_${var.name}"
}

resource "lxd_profile" "profile" {
  name = "profile_${var.name}"

  config = {
    "boot.autostart" = true
    "limits.cpu"     = var.cpu
    "limits.memory"  = var.memory
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = "br0"
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }
}

resource "lxd_container" "node" {
  for_each = { for i in var.node_names : i.name => i }
  target   = contains(keys(each.value), "target") ? each.value.target : null
  config = {
    ip_address = contains(keys(each.value), "ip_address") ? each.value.ip_address : null
  }

  name = each.value.name

  image = "nixos"

  profiles = ["${lxd_profile.profile.name}"]
}
