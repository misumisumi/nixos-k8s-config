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
  for_each = var.node_names

  name = each.value

  image = "nixos"

  profiles = ["${lxd_profile.profile.name}"]
}