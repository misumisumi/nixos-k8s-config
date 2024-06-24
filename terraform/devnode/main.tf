# https://github.com/NixOS/nixpkgs/issues/283015
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.4"
    }
  }
}

locals {
  disks = flatten([for node in flatten(var.nodes) :
    concat([{
      name         = "${node.distro}-${node.name}"
      size         = node.config.root_size
      storage_pool = node.config.storage_pool
    }], [for disk in flatten(node.disks) : disk])
  ])
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "volume" {
  for_each = { for i in local.disks : i.name => i }
  name     = each.value.name
  pool     = each.value.storage_pool
  size     = each.value.size
}

resource "libvirt_domain" "node" {
  for_each = { for i in var.nodes : i.name => i }

  name     = "${each.value.distro}-${each.value.name}"
  firmware = each.value.config.firmware
  emulator = each.value.config.emulator
  machine  = "q35"
  memory   = each.value.config.memory
  vcpu     = each.value.config.vcpu
  cpu {
    mode = each.value.config.cpu_mode
  }

  # For root disk
  disk {
    volume_id = libvirt_volume.volume["${each.value.distro}-${each.value.name}"].id
  }

  # For external disk
  dynamic "disk" {
    for_each = each.value.disks
    content {
      volume_id = libvirt_volume.volume["${disk.value.name}"].id
    }
  }

  network_interface {
    bridge    = each.value.network.bridge
    mac       = each.value.network.mac_address
    addresses = each.value.network.addresses
    hostname  = each.value.name
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
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  xml {
    xslt = file("use-sata.xsl")
  }
}
