compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "leaf"
        root_pool = "baremetal"
        root_size = "16GB"
      },
    ]
    instances = [
      {
        name         = "leaf4"
        image        = "mylab/leaf4"
        machine_type = "virtual-machine"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        profiles = ["leaf"]
        networks = [
          {
            parent       = "br0-1g"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "br0-10g"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "br0-40g"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
        ]
      },
      {
        name         = "leaf5"
        image        = "mylab/leaf5"
        machine_type = "virtual-machine"
        profiles     = ["leaf"]
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent       = "br1-1g"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "br1-10g"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "br0-40g"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
        ]
      },
      # {
      #   name         = "leaf6"
      #   image        = "mylab/leaf6"
      #   machine_type = "virtual-machine"
      #   profiles     = ["leaf"]
      #   config = {
      #     "limits.cpu"    = 2
      #     "limits.memory" = "4GB"
      #   }
      #   networks = [
      #     {
      #       parent       = "br2-1g"
      #       nictype      = "bridged"
      #       "limits.max" = "1000Mbit"
      #     },
      #     {
      #       parent       = "br2-10g"
      #       nictype      = "bridged"
      #       "limits.max" = "2000Mbit"
      #     },
      #     {
      #       parent       = "br0-40g"
      #       nictype      = "bridged"
      #       "limits.max" = "3000Mbit"
      #     },
      #   ]
      # },
      # {
      #   name         = "leaf7"
      #   image        = "mylab/leaf7"
      #   machine_type = "virtual-machine"
      #   profiles     = ["leaf"]
      #   config = {
      #     "limits.cpu"    = 2
      #     "limits.memory" = "4GB"
      #   }
      #   networks = [
      #     {
      #       parent       = "br3-1g"
      #       nictype      = "bridged"
      #       "limits.max" = "1000Mbit"
      #     },
      #     {
      #       parent       = "br3-10g"
      #       nictype      = "bridged"
      #       "limits.max" = "2000Mbit"
      #     },
      #     {
      #       parent       = "br0-40g"
      #       nictype      = "bridged"
      #       "limits.max" = "3000Mbit"
      #     },
      #   ]
      # },
    ]
  }
]
