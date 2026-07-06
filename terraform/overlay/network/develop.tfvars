networks = {
  dev-p2p-0 = {
    config = {
      "bridge.driver" = "openvswitch"
      "dns.mode"      = "none"
      "ipv4.address"  = "none"
      "ipv4.nat"      = false
      "ipv4.dhcp"     = false
      "ipv4.firewall" = false
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = false
    }
  },
  dev-k8s = {
    config = {
      "bridge.driver" = "openvswitch"
      "dns.mode"      = "none"
      "ipv4.address"  = "172.16.100.1/24"
      "ipv4.nat"      = true
      "ipv4.dhcp"     = true
      "ipv4.firewall" = false
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = false
    }
  }
  dev-shared = {
    config = {
      "bridge.driver" = "openvswitch"
      "dns.mode"      = "none"
      "ipv4.address"  = "172.16.1.100/24"
      "ipv4.nat"      = true
      "ipv4.dhcp"     = true
      "ipv4.firewall" = false
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = false
    }
  }
}
