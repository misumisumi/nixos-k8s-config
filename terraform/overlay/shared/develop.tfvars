compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "dns"
        root_pool = "instances"
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
        machine_type = "virtual-machine"
        profiles     = ["dns"]
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
        machine_type = "virtual-machine"
        profiles     = ["dns"]
        networks = [
          {
            parent         = "dev-shared"
            nictype        = "bridged"
            "ipv4.address" = "172.16.1.2"
          },
        ]
      },
      # {
      #   name     = "pi-hole"
      #   image    = "dev/nodes/pi-hole"
      #   profiles = ["dns"]
      #   networks = [
      #     {
      #       parent         = "dev-shared"
      #       nictype        = "bridged"
      #       "ipv4.address" = "172.16.1.3"
      #     },
      #   ]
      # },
    ]
  }
]
