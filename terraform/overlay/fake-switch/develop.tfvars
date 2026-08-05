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
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.5"
          },
        ]
      },
    ]
  }
]
