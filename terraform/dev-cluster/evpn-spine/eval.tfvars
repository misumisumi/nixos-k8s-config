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
        image        = "mylab/ix2215"
        machine_type = "virtual-machine"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        profiles = ["spine"]
        networks = [
          {
            parent       = "br0-1g"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "br1-1g"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "br2-1g"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "br3-1g"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
        ]
      },
      {
        name         = "spine2"
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
            parent       = "br0-40g"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
        ]
      },
      {
        name         = "spine3"
        image        = "mylab/spine3"
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
