compornents = [
  {
    remote   = "local"
    profiles = []
    instances = [
      {
        name         = "router"
        image        = "mylab/tiny-router"
        machine_type = "container"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent  = "dev-wan"
            nictype = "bridged"
          },
          {
            parent  = "dev-lan"
            nictype = "bridged"
          },
          # {
          #   name    = "eth1.210"
          #   parent  = "dev-lan.210"
          #   nictype = "bridged"
          # },
        ]
        devices = [
          {
            name = "ipxe-images"
            type = "disk"

            properties = {
              path   = "/var/www"
              source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/nix/my-lab/instances/tiny-router/www"
            }
          }
        ]
      },
    ]
  }
]
