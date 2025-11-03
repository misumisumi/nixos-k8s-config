networks = {
  dev-lan = {
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
  "dev-lan.210" = {
    config = {
      "bridge.driver"              = "openvswitch"
      "bridge.external_interfaces" = "br0.210/br0/210"
      "ipv4.address"               = "none"
      "ipv4.nat"                   = false
      "ipv4.dhcp"                  = false
      "ipv4.firewall"              = true
      "ipv6.address"               = "none"
      "ipv6.nat"                   = false
      "ipv6.dhcp"                  = false
      "ipv6.firewall"              = true
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
