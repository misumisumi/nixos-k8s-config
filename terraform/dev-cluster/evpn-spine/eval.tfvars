compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "spine"
        root_pool = "baremetal"
        root_size = "6GB"
      },
    ]
    instances = [
      {
        name         = "spine1"
        image        = "mylab/ibl2"
        machine_type = "virtual-machine"
        profiles     = ["spine"]
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent       = "br0-40g"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
          {
            parent       = "br1-40g"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
          {
            parent       = "br2-40g"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
          {
            parent       = "br3-40g"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
          {
            parent       = "br3-10g"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "brx-wan"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
        ]
      },
      {
        name         = "spine2"
        image        = "mylab/spine2"
        machine_type = "virtual-machine"
        profiles     = ["spine"]
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent       = "br0-10g"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "br1-10g"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "br2-10g"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "br3-10g"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
        ]
      },
    ]
  }
]
