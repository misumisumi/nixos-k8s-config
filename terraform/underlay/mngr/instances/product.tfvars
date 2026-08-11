compornents = [{
  remote  = "local"
  project = "homelab-prod"
  profiles = [
    {
      name = "prod.mngr"
      config = {
        "limits.cpu"    = 1
        "limits.memory" = "2GB"
      }
    },
    {
      name      = "prod.empty-vm"
      root_size = "1MB"
    },
  ]
  instances = [
    {
      name         = "naokosan"
      image        = "prod/mngr/naokosan"
      machine_type = "container"
      profiles     = ["prod.mngr"]
      networks = [
        {
          parent  = "br0"
          nictype = "bridged"
          vlan    = 10
        },
      ]
    },
    {
      name         = "image-server"
      image        = "prod/mngr/image-server"
      machine_type = "container"
      profiles     = ["prod.mngr"]
      networks = [
        {
          parent  = "br0"
          nictype = "bridged"
          vlan    = 10
        },
      ]
      devices = [
        {
          name = "ipxe-images",
          type = "disk",
          properties = {
            source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/mnt/production/www/images/ipxe"
            path   = "/var/www/images/ipxe"
          }
        },
        {
          name = "kexec-images",
          type = "disk",
          properties = {
            source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/mnt/production/www/images/kexec"
            path   = "/var/www/images/kexec"
          }
        }
      ]
    },
    {
      name         = "test"
      machine_type = "virtual-machine"
      profiles     = ["prod.empty-vm"]
      config = {
        "limits.cpu"    = 4
        "limits.memory" = "8GB"
      }
      networks = [
        {
          parent  = "br0"
          nictype = "bridged"
          vlan    = 10
        },
      ]
    }
  ]
}]
