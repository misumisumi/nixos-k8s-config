terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_network" "lxd_network" {
  name = var.name

  config = {
    "ipv4.address" = var.ipv4_address
    "ipv4.nat"     = var.nat
    "ipv6.address" = var.ipv6_address
    "ipv6.nat"     = var.nat
  }
}

