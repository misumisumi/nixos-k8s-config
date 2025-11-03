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
            parent  = "dev-cluster-wan"
            nictype = "bridged"
          },
          {
            parent  = "dev-cluster-lan"
            nictype = "bridged"
            # "vlan.tagged" = "210"
          },
        ]
        devices = [
          {
            name = "ipxe-images"
            type = "disk"

            properties = {
              path   = "/var/www/ipxe"
              source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/nix/my-lab/instances/tiny-router/ipxe"
            }
          }
        ]
      },
    ]
  }
]
