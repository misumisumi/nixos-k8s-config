compornents = [
  {
    remote   = "local"
    profiles = []
    instances = [
      {
        name         = "admiral"
        image        = "mngr/admiral"
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
            parent  = "dev-1g-0"
            nictype = "bridged"
          },
        ]
      },
      {
        name         = "image-server"
        image        = "mngr/image-server"
        machine_type = "container"
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
        devices = [
          {
            name = "ipxe-images"
            type = "disk"

            properties = {
              path   = "/var/www"
              source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/nix/my-lab/guests/mngr/image-server/common/www"
            }
          }
        ]
      },
    ]
  }
]
