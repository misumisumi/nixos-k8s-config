networks = {
  dev-1g-0 = {
    config = {
      "bridge.driver" = "openvswitch"
      "dns.mode"      = "none"
      "ipv4.address"  = "192.168.20.254/24"
      "ipv4.nat"      = false
      "ipv4.dhcp"     = false
      "ipv4.firewall" = false
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = false
    }
  },
  dev-10g-0 = {
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
  dev-10g-1 = {
    config = {
      "bridge.driver" = "openvswitch"
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
  dev-10g-2 = {
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
  dev-10g-3 = {
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
  dev-40g-0 = {
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
  dev-40g-1 = {
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
  dev-40g-2 = {
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
  dev-40g-3 = {
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
  dev-wan = {
    config = {
      "bridge.driver" = "openvswitch"
      "ipv4.address"  = "none"
      "ipv4.nat"      = false
      "ipv4.dhcp"     = false
      "ipv4.firewall" = false
      "ipv6.address"  = "none"
      "ipv6.nat"      = false
      "ipv6.dhcp"     = false
      "ipv6.firewall" = false
    }
  }
  dev-isp = {
    config = {
      "bridge.driver" = "openvswitch"
      "ipv4.address"  = "10.150.150.1/24"
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
