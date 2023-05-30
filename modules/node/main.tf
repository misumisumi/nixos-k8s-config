# Spawns the given amount of machines,
# using the given base image as their root disk,
# attached to the same network.

terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
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
      parent  = var.nic_parent
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
