networks = {
  dev-k8s-net = {
    config = {
      "bridge.driver" = "openvswitch"
      "dns.mode"      = "none"
      "ipv4.address"  = "10.10.100.1/24"
      "ipv4.nat"      = false
      "ipv4.dhcp"     = true
      "ipv4.firewall" = false
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = false
    }
  }
}
