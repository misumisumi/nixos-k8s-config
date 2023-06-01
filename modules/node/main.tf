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

locals {
  raw_lxc = <<EOT
lxc.apparmor.profile = unconfined
lxc.cap.drop = ""
lxc.cgroup.devices.allow = a
EOT
}

resource "lxd_profile" "profile" {
  name = "profile_${var.name}"

  config = {
    # "security.privileged" = true
    "security.nesting" = true
    "boot.autostart"   = true
    "limits.cpu"       = tonumber(var.node_rd.cpu)
    "limits.memory"    = var.node_rd.memory
    "raw.lxc"          = local.raw_lxc
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }
  device {
    type = "unix-block"
    name = "loop0"
    properties = {
      path = "/dev/loop0"
    }
  }
}

resource "lxd_container" "node" {
  for_each = { for i in var.nodes : i.name => i }
  target   = contains(keys(each.value), "target") ? each.value.target : null

  name = each.value.name

  image = "nixos"

  profiles = ["${lxd_profile.profile.name}"]

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype        = "bridged"
      parent         = terraform.workspace == "develop" ? "k8sbr0" : var.node_rd.nic_parent
      "ipv4.address" = contains(keys(each.value), "ip_address") && terraform.workspace == "develop" ? each.value.ip_address : null
    }
  }
}
