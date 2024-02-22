resource "incus_network" "incus_network" {
  name = var.name

  config = {
    "ipv4.address" = var.ipv4_address
    "ipv4.nat"     = var.nat
    "ipv6.address" = var.ipv6_address
    "ipv6.nat"     = var.nat
  }
}

