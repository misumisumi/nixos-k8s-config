compornents = [
  {
    remote = "local"
    profiles = [{
      name = "mngr"
    }]
    instances = [
      {
        name         = "admiral"
        image        = "test/mngr/admiral"
        machine_type = "container"
        profiles     = ["mngr"]
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
        image        = "test/mngr/image-server"
        machine_type = "container"
        profiles     = ["mngr"]
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
            name = "www-root"
            type = "disk"

            properties = {
              path   = "/var/www"
              source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/nix/my-lab/guests/mngr/image-server/common/www"
            }
          },
        ]
      },
      {
        name         = "test"
        machine_type = "virtual-machine"
        profiles     = ["mngr"]
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "12GB"
        }
        networks = [
          {
            parent  = "dev-1g-0"
            nictype = "bridged"
          },
        ]
      },
    ]
  }
]
