compornents = [
  {
    remote = "local"
    profiles = [
      {
        tag          = "nfs"
        root_pool    = "instances"
        machine_type = "virtual-machine"
      }
    ]
    instances = [
      {
        name         = "nfs1"
        machine_type = "virtual-machine"
        image        = "images:fedora/40/cloud"
        network_config = {
          parent         = "k8sbr0"
          hwaddr         = "56:f1:ff:2a:76:c5"
          "ipv4.address" = "10.150.10.71"
        }
        cloudinit = {
          template_file = "local-dev.yaml.tftpl"
          sops_file     = "../../sops/users/admin/secrets.yaml"
          hosts_file    = "./local-dev.hosts.json"
          vars = {
            username = "almalinux"
          }
        }
        config = {}
        limits = {
          cpu    = "2"
          memory = "4GiB"
        }
        devices = [
          {
            name = "nfs"
            type = "disk"
            properties = {
              pool   = "nfs"
              source = "nfs1"
            }
          }
        ]
      },
      {
        name         = "nfs2"
        machine_type = "virtual-machine"
        image        = "images:fedora/40/cloud"
        network_config = {
          parent         = "k8sbr0"
          hwaddr         = "8e:4a:33:ed:65:eb"
          "ipv4.address" = "10.150.10.72"
        }
        cloudinit = {
          template_file = "local-dev.yaml.tftpl"
          sops_file     = "../../sops/users/admin/secrets.yaml"
          hosts_file    = "./local-dev.hosts.json"
          vars = {
            username = "almalinux"
          }
        }
        config = {}
        limits = {
          cpu    = "2"
          memory = "4GiB"
        }
        devices = [
          {
            name = "nfs"
            type = "disk"
            properties = {
              pool   = "nfs"
              source = "nfs2"
            }
          }
        ]
      },
    ]
  }
]
