networks = {
  dev-1g = {
    config = {
      "bridge.driver" = "openvswitch"
      "ipv4.address"  = "none"
      "ipv4.nat"      = false
      "ipv4.dhcp"     = false
      "ipv4.firewall" = true
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = true
    }
  },
  dev-10g = {
    config = {
      "bridge.driver" = "openvswitch"
      "ipv4.address"  = "none"
      "ipv4.nat"      = false
      "ipv4.dhcp"     = false
      "ipv4.firewall" = true
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = true
    }
  },
  dev-40g = {
    config = {
      "bridge.driver" = "openvswitch"
      "ipv4.address"  = "none"
      "ipv4.nat"      = false
      "ipv4.dhcp"     = false
      "ipv4.firewall" = true
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = true
    }
  },
  dev-wan = {
    config = {
      "ipv4.address"  = "10.0.150.1/24"
      "ipv4.nat"      = true
      "ipv4.dhcp"     = true
      "ipv4.firewall" = true
      "ipv6.address"  = "fd42:3a98:dc40:52c6::1/64"
      "ipv6.nat"      = true
      "ipv6.dhcp"     = true
      "ipv6.firewall" = true
    }
  }
}
