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
  mkvolumes = [for device in flatten(var.nodes[*].devices[*]) :
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
}

module "volume" {
  source  = "../volume"
  volumes = local.mkvolumes
}

resource "lxd_instance" "node" {
  for_each = { for i in var.nodes : i.name => i }
  target   = each.value.target

  name      = each.value.name
  type      = each.value.type
  image     = "nixos/lxc-${each.value.type}"
  ephemeral = false

  config = {
    "boot.autostart"                            = var.node_config.boot_autostart
    "security.nesting"                          = true
    "security.syscalls.intercept.mount"         = true
    "security.syscalls.intercept.mount.allowed" = "ext4"
    "raw.lxc"                                   = <<EOT
        lxc.apparmor.profile = unconfined
        lxc.cap.drop = ""
        lxc.cgroup.devices.allow = a
    EOT
  }
  limits = {
    cpu    = var.node_config.cpu
    memory = var.node_config.memory
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype        = "bridged"
      parent         = var.node_config.nic_parent
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
  depends_on = [module.volume]
}