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

resource "incus_volume" "volume" {
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

resource "incus_profile" "profile" {
  for_each = { for i in var.profiles : i.tag => i }
  name     = "profile_${each.value.tag}"
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
}

# resource "incus_image" "image" {
#   for_each      = { for i in var.instances : i.name => i }
#   source_remote = var.source_remote
#   source_image  = each.value.distro
#   type          = each.value.machine_type
#   # aliases       = ["${each.value.distro}/${each.value.machine_type}"]
#   copy_aliases = true
# }

resource "incus_instance" "instance" {
  for_each = { for i in var.instances : i.name => i }
  remote   = var.remote
  project  = var.project

  name      = each.value.name
  type      = each.value.machine_type
  image     = each.value.image
  ephemeral = false
  profiles  = ["profile_${replace(each.value.name, "/[[:digit:]]+/", "")}"]

  config = each.value.machine_type == "container" ? merge({
    "security.syscalls.intercept.mount"         = true
    "security.syscalls.intercept.mount.allowed" = "ext4"
    "raw.lxc"                                   = <<EOT
        lxc.apparmor.profile = unconfined
        lxc.cap.drop = ""
        lxc.cgroup.devices.allow = a
    EOT
    }, each.value.config) : merge({
    "security.secureboot" = false
  }, each.value.config)

  limits = merge({
    cpu    = 2
    memory = "1GB"
  }, each.value.limits)

  device {
    name = "eth0"
    type = "nic"

    properties = merge({
      nictype = "bridged"
      host_name = format(each.value.machine_type == "container" ? "veth_%s%s" : "tap_%s%s",
        substr(each.value.name, 0, 3),
        substr(each.value.name, -1, -1)
      ) }, each.value.network_config
    )
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

