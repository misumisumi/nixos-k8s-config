compornents = [{
  remote = "local"
  profiles = [
    {
      name = "dev.mngr"
    },
  ]
  instances = [
    {
      name         = "naokosan"
      image        = "dev/mngr/naokosan"
      machine_type = "container"
      profiles     = ["dev.mngr"]
      config = {
        "limits.cpu"    = 2
        "limits.memory" = "4GB"
      }
      networks = [
        {
          parent        = "br0"
          nictype       = "bridged"
          "vlan.tagged" = 10
        },
      ]
    },
    # {
    #   name         = "image-server"
    #   image        = "dev/mngr/image-server"
    #   machine_type = "container"
    #   profiles     = ["dev.mngr"]
    #   config = {
    #     "limits.cpu"    = 2
    #     "limits.memory" = "4GB"
    #   }
    #   networks = [
    #     {
    #       parent  = "dev-1g-0"
    #       nictype = "bridged"
    #       vlan    = 10
    #     },
    #   ]
    #   devices = [
    #     {
    #       name = "images",
    #       type = "disk",
    #       properties = {
    #         source = "/home/sumi/Workspace/nix/server/nixos-k8s-config/mnt/develop/www/images/kexec"
    #         path   = "/var/www/images/kexec"
    #       }
    #     }
    #   ]
    # },
  ]
}]
