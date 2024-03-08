terraform {
  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.5.1"
    }
    libvirt = {
      source  = "registry.terraform.io/dmacvicar/libvirt"
      version = "~> 0.7.4"
    }
  }
}

locals {
  disks = flatten([for node in flatten(var.nodes) :
    concat([{
      name = "${var.distro}-${node.name}"
      size = node.root_size
    }], [for disk in flatten(node.disks) : disk])
  ])
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "volume" {
  for_each = { for i in local.disks : i.name => i }
  name     = each.value.name
  pool     = var.pool
  size     = each.value.size
}

resource "libvirt_domain" "node" {
  for_each = { for i in var.nodes : i.name => i }

  name     = "${var.distro}-${each.value.name}"
  firmware = var.firmware
  emulator = var.emulator
  machine  = "q35"
  memory   = var.memory
  vcpu     = var.vcpu

  # For root disk
  disk {
    volume_id = libvirt_volume.volume["${var.distro}-${each.value.name}"].id
  }

  # For external disk
  dynamic "disk" {
    for_each = each.value.disks
    content {
      volume_id = libvirt_volume.volume["${disk.value.name}"].id
    }
  }

  network_interface {
    bridge = var.bridge
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
  video {
    type = "qxl"
  }
  boot_device {
    dev = ["hd", "cdrom", "network"]
  }
  xml {
    xslt = file("use-sata.xsl")
  }
}
