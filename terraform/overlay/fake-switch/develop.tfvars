compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "fake"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "4GB"
        }
      },
    ]
    instances = [
      {
        name         = "spine"
        image        = "dev/fake/spine"
        machine_type = "virtual-machine"
        profiles     = ["fake"]
        networks = [
          {
            parent  = "dev-p2p-0"
            nictype = "bridged"
          },
        ]
      },
      {
        name         = "leaf"
        image        = "dev/fake/leaf"
        machine_type = "virtual-machine"
        profiles     = ["fake"]
        networks = [
          {
            parent  = "dev-p2p-0"
            nictype = "bridged"
          },
          {
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.5"
          },
          {
            parent         = "dev-vault"
            nictype        = "bridged"
            "ipv4.address" = "172.16.11.254"
          },
          {
            parent         = "dev-proxy"
            nictype        = "bridged"
            "ipv4.address" = "172.16.10.254"
          },
          {
            parent         = "dev-shared"
            nictype        = "bridged"
            "ipv4.address" = "172.16.1.253"
          },
        ]
      },
    ]
  }
]
