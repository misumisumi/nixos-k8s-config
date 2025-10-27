# Spawns the given amount of machines,
# using the given base image as their root disk,
# attached to the same network.
terraform {
  required_providers {
    incus = {
      source = "registry.opentofu.org/lxc/incus"
    }
    random = {
      source = "registry.opentofu.org/hashicorp/random"
    }
    sops = {
      source = "carlpett/sops"
    }
  }
}

locals {
  _volumes = flatten([for instance in flatten(var.instances[*]) :
    [for device in flatten(instance.devices[*]) :
      device.type == "disk" && device.create && contains(keys(device.properties), "pool") ? {
        name         = device.properties.source
        remote       = var.remote
        pool         = device.properties.pool
        content_type = instance.machine_type == "container" ? "filesystem" : "block"
      } : null
    ]
  ])
  volumes = [for volume in local._volumes : volume if volume != null]
}

resource "incus_storage_volume" "volume" {
  for_each     = { for i in local.volumes : i.name => i }
  name         = each.value.name
  remote       = var.remote
  project      = var.project
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

data "sops_file" "cloudinit" {
  for_each    = { for i in var.instances : i.name => i if i.cloudinit.sops_file != "" }
  source_file = each.value.cloudinit.sops_file
}

resource "incus_profile" "profile" {
  for_each = { for i in var.profiles : i.name => i }
  name     = each.value.name
  remote   = var.remote
  project  = var.project

  config = merge({
    "boot.autostart" = each.value.auto_start
  }, each.value.config)

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = each.value.root_pool
      path = "/"
      size = each.value.root_size
    }
  }
  dynamic "device" {
    for_each = each.value.machine_type == "virtual-machine" ? concat([{
      name = "agent"
      type = "disk"
      properties = {
        source = "agent:config"
      }
    }], each.value.devices) : each.value.devices
    content {
      type       = device.value.type
      name       = device.value.name
      properties = device.value.properties
    }
  }
}

resource "incus_instance" "instance" {
  for_each = { for i in var.instances : i.name => i }
  remote   = var.remote
  project  = var.project

  name      = each.value.name
  type      = each.value.machine_type
  image     = each.value.image
  ephemeral = false
  profiles  = each.value.profiles != [] ? each.value.profiles : ["${replace(each.value.name, "/[[:digit:]]+/", "")}"]

  config = merge(
    each.value.machine_type == "container" ? {
      "security.syscalls.intercept.mount"         = true
      "security.syscalls.intercept.mount.allowed" = "ext4"
      "raw.lxc"                                   = <<EOT
        lxc.apparmor.profile = unconfined
        lxc.cap.drop = ""
        lxc.cgroup.devices.allow = a
    EOT
      } : {
      "security.secureboot" = false
    },
    each.value.cloudinit.template_file != "" ? regex("(\\.[^.]+)$", each.value.cloudinit.template_file) == ".tftpl" ? {
      "cloud-init.user-data" = templatefile(each.value.cloudinit.template_file,
        {
          secrets = yamldecode(data.sops_file.cloudinit[each.key].raw),
          vars    = each.value.cloudinit.vars
          hosts   = jsondecode(file(each.value.cloudinit.hosts_file))
        }
      )
      } : {
      "cloud-init.user-data" = file(each.value.cloudinit.template_file)
    }
    : {},
    each.value.config
  )

  dynamic "device" {
    for_each = each.value.networks
    content {
      name = format("eth%d", device.key)
      type = "nic"
      properties = merge({
        host_name = format(each.value.machine_type == "container" ? "veth_%s%s_%s" : "tap_%s%s_%s",
          substr(each.value.name, 0, 3),
          substr(each.value.name, -1, -1),
          device.key
        ) }, device.value
      )
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
  depends_on = [incus_storage_volume.volume, incus_profile.profile]
}
