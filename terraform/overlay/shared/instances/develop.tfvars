compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    profiles = [
      {
        name      = "shared"
        root_pool = "shared"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "1GB"
        }
      },
    ]
    instances = [
      {
        name         = "resolver"
        image        = "dev/shared/resolver"
        machine_type = "container"
        profiles     = ["shared"]
        networks = [
          {
            parent         = "dev-shared"
            nictype        = "bridged"
            "ipv4.address" = "172.16.1.1"
          },
        ]
      },
      {
        name         = "dns"
        image        = "dev/shared/dns"
        machine_type = "container"
        profiles     = ["shared"]
        networks = [
          {
            parent         = "dev-shared"
            nictype        = "bridged"
            "ipv4.address" = "172.16.1.2"
          },
        ]
        devices = [
          {
            name   = "pdns"
            create = false
            type   = "disk"
            properties = {
              source = "shared"
              pool   = "pdns"
              path   = "/var/lib/powerdns"
            }
          }
        ]
      },
    ]
  }
]
