terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_network" "k8sbr0" {
  name = var.name

  config = {
    "ipv4.address" = var.ipv4_address
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    "ipv6.nat"     = "false"
  }
}