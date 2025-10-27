compornents = [
  {
    remote   = "local"
    profiles = []
    instances = [
      {
        name         = "ix2215"
        image        = "images:openwrt/24.10"
        machine_type = "container"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent  = "dev-cluster-wan"
            nictype = "bridged"
          },
          {
            parent  = "dev-cluster-lan"
            nictype = "bridged"
          },
        ]
      },
    ]
  }
]

