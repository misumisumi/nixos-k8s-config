compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "dev.spine"
        root_pool = "dev-baremetal"
        root_size = "16GB"
      },
      {
        name      = "dev.leaf"
        root_pool = "dev-baremetal"
        root_size = "16GB"
      },
      {
        name = "dev.mngr"
      },
    ]
    instances = [
      {
        name         = "fake-isp"
        image        = "dev/mngr/fake-isp"
        machine_type = "container"
        profiles     = ["dev.mngr"]
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent  = "dev-isp"
            nictype = "bridged"
          },
          {
            parent  = "dev-wan"
            nictype = "bridged"
          },
        ]
      },
      {
        name         = "phikun"
        image        = "dev/mngr/phikun"
        machine_type = "container"
        profiles     = ["dev.mngr"]
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent  = "dev-1g-0"
            nictype = "bridged"
          },
        ]
      },
      {
        name         = "kaho"
        image        = "dev/switch/kaho"
        machine_type = "virtual-machine"
        profiles     = ["dev.spine"]
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent       = "dev-wan"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-10g-3"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "dev-40g-0"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
          {
            parent       = "dev-40g-1"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
          {
            parent       = "dev-40g-2"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
          {
            parent       = "dev-40g-3"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
        ]
      },
      {
        name         = "ajisai"
        image        = "dev/compute/ajisai"
        machine_type = "virtual-machine"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        profiles = ["dev.leaf"]
        networks = [
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-10g-0"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "dev-40g-0"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
        ]
        devices = [
          {
            name   = "linstor"
            type   = "disk"
            create = false
            properties = {
              pool   = "dev-linstor"
              source = "linstor1"
            }
          }
        ]
      },
      {
        name         = "mai"
        image        = "dev/compute/mai"
        machine_type = "virtual-machine"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        profiles = ["dev.leaf"]
        networks = [
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-10g-1"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "dev-40g-1"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
        ]
        devices = [
          {
            name   = "linstor"
            type   = "disk"
            create = false
            properties = {
              pool   = "dev-linstor"
              source = "linstor2"
            }
          }
        ]
      },
      {
        name         = "satsuki"
        image        = "dev/compute/satsuki"
        machine_type = "virtual-machine"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        profiles = ["dev.leaf"]
        networks = [
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-10g-2"
            nictype      = "bridged"
            "limits.max" = "2000Mbit"
          },
          {
            parent       = "dev-40g-2"
            nictype      = "bridged"
            "limits.max" = "3000Mbit"
          },
        ]
        devices = [
          {
            name   = "linstor"
            type   = "disk"
            create = false
            properties = {
              pool   = "dev-linstor"
              source = "linstor3"
            }
          }
        ]
      },
    ]
  }
]
