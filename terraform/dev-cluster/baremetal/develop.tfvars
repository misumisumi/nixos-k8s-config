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
        name      = "dev.sks8300-8x"
        root_pool = "dev-baremetal"
        root_size = "1GB"
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
        name         = "sks8300-8x"
        image        = "dev/switch/sks8300-8x"
        machine_type = "virtual-machine"
        profiles     = ["dev.sks8300-8x"]
        config = {
          "limits.cpu"    = 1
          "limits.memory" = "512MB"
          "raw.qemu"      = "-uuid b1ccb119-cad5-4f82-830f-313c4744bc3c"
        }
        networks = [
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-0"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-1"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-2"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-3"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
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
          "raw.qemu"      = "-uuid 501b2357-38e9-43ad-a841-1b620418c959"
        }
        networks = [
          {
            parent       = "dev-wan"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-3"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-40g-0"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-40g-1"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-40g-2"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
          },
          {
            parent       = "dev-40g-3"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
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
          "raw.qemu"      = "-uuid e6ae54f8-c9b9-4bc0-a3a2-70818ed1a0d2"
        }
        profiles = ["dev.leaf"]
        networks = [
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-0"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-40g-0"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
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
          "raw.qemu"      = "-uuid 27161944-492d-4225-ae42-73a43467e797"
        }
        profiles = ["dev.leaf"]
        networks = [
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-1"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-40g-1"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
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
          "raw.qemu"      = "-uuid ef44a86f-544b-4e81-8fa3-0e7bbe8609b6"
        }
        profiles = ["dev.leaf"]
        networks = [
          {
            parent       = "dev-1g-0"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-10g-2"
            nictype      = "bridged"
            "limits.max" = "500Mbit"
          },
          {
            parent       = "dev-40g-2"
            nictype      = "bridged"
            "limits.max" = "1000Mbit"
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
