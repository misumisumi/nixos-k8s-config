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
  mkvolumes = [for device in flatten(var.instances[*].devices[*]) :
    device.type == "disk" && contains(keys(device.properties), "pool") ? {
      name         = device.properties.source
      pool         = device.properties.pool
      content_type = device.content_type
      } : {
      name         = null
      pool         = null
      content_type = null
    }
  ]
  remotes = [for remote in var.instances[*].remote : remote]
}

module "volume" {
  source  = "../volume"
  volumes = local.mkvolumes
}

resource "lxd_profile" "profile" {
  name     = "profile_${var.tag}"
  for_each = toset(local.remotes)
  remote   = each.value

  config = {
    "boot.autostart" = var.instance_config.boot_autostart
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
      size = var.instance_config.root_size
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

resource "lxd_instance" "instance" {
  for_each = { for i in var.instances : i.name => i }
  remote   = each.value.remote

  name      = each.value.name
  type      = each.value.type
  image     = "nixos/lxc-${each.value.type}"
  ephemeral = false
  profiles  = ["profile_${var.tag}"]

  config = each.value.type == "container" ? {
    "security.syscalls.intercept.mount"         = true
    "security.syscalls.intercept.mount.allowed" = "ext4"
    "raw.lxc"                                   = <<EOT
        lxc.apparmor.profile = unconfined
        lxc.cap.drop = ""
        lxc.cgroup.devices.allow = a
    EOT
    } : {
    "security.secureboot" = false
  }
  limits = {
    cpu    = var.instance_config.cpu
    memory = var.instance_config.memory
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype        = "bridged"
      parent         = var.instance_config.nic_parent
      "ipv4.address" = contains(keys(each.value), "ip_address") && terraform.workspace != "product" ? each.value.ip_address : null
    }
  }
  dynamic "device" {
    for_each = each.value.devices
    content {
      type       = device.value.type
      name       = device.value.name
      properties = device.value.properties
    }
  }
  depends_on = [module.volume, lxd_profile.profile]
}
