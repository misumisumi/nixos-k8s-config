compornents = [
  {
    remote = "local"
    profiles = [{
      name = "mngr"
    }]
    instances = [
      {
        name         = "admiral"
        image        = "dev/mngr/admiral"
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
        image        = "dev/mngr/image-server"
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
            name = "ipxe-images"
            type = "disk"

            properties = {
              path   = "/var/www/ipxe/images"
              source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/mnt/develop/www/ipxe/images"
            }
          },
          {
            name = "kexec-images"
            type = "disk"

            properties = {
              path   = "/var/www/kexec/images"
              source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/mnt/develop/www/kexec/images"
            }
          },
        ]
      },
      {
        name         = "empty-vm"
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
