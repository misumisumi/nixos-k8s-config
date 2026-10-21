compornents = [{
  remote  = "local"
  project = "homelab-prod"
  profiles = [
    {
      name        = "prod.mngr"
      "root_pool" = "prod-mngr"
      config = {
        "limits.cpu"    = 1
        "limits.memory" = "2GB"
      }
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
  ]
}]
