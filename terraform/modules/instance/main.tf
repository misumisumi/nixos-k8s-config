# Spawns the given amount of machines,
# using the given base image as their root disk,
# attached to the same network.
terraform {
  required_providers {
    incus = {
      source  = "registry.terraform.io/lxc/incus"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
    }
  }
}

locals {
  _volumes = flatten([for instance in flatten(var.instances[*]) :
    [for device in flatten(instance.devices[*]) :
      device.type == "disk" && contains(keys(device.properties), "pool") ? {
        name         = device.properties.source
        remote       = instance.remote
        pool         = device.properties.pool
        content_type = device.content_type
      } : null
    ]
  ])
  volumes = [for volume in local._volumes : volume if volume != null]
  remotes = [for remote in var.instances[*].remote : remote]
}

resource "incus_volume" "volume" {
  for_each     = { for i in local.volumes : i.name => i }
  name         = each.value.name
  remote       = each.value.remote
  pool         = each.value.pool
  content_type = each.value.content_type
}

resource "random_id" "host_id" {
  for_each = { for i in var.instances : i.name => i }
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    host_id = each.value.name
  }
  byte_length = 4
}

resource "incus_profile" "profile" {
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
}

resource "incus_instance" "instance" {
  for_each = { for i in var.instances : i.name => i }
  remote   = each.value.remote

  name      = each.value.name
  type      = var.instance_config.machine_type
  image     = "${var.instance_config.image}/lxc-${var.instance_config.machine_type}"
  ephemeral = false
  profiles  = ["profile_${var.tag}"]

  config = var.instance_config.machine_type == "container" ? {
    "security.syscalls.intercept.mount"         = true
    "security.syscalls.intercept.mount.allowed" = var.instance_config.mount_fs
    "raw.lxc"                                   = <<EOT
        lxc.apparmor.profile = unconfined
        lxc.cap.drop = ""
        lxc.cgroup.devices.allow = a
    EOT
    } : {
    "security.secureboot" = false
  }
  limits = {
    cpu    = each.value.cpu == null ? var.instance_config.cpu : each.value.cpu
    memory = each.value.memory == null ? var.instance_config.memory : each.value.memory
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = var.instance_config.nic_parent
      host_name = format(var.instance_config.machine_type == "container" ? "veth_%s%s" : "tap_%s%s",
        substr(each.value.name, 0, 3),
        substr(each.value.name, -1, -1)
      )
      "ipv4.address" = each.value.ipv4_address
      "ipv6.address" = each.value.ipv6_address
      "hwaddr"       = each.value.mac_address
      vlan           = var.instance_config.vlan
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
  depends_on = [incus_volume.volume, incus_profile.profile]
}

