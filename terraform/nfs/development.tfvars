compornents = [
  {
    remote = "local"
    profiles = [
      { tag       = "nfs"
        root_pool = "test"
      }
    ]
    instances = [
      {
        name         = "nfs1"
        machine_type = "virtual-machine"
        distro       = "almalinux9"
        network_config = {
          "ipv4.address" = "10.150.10.70"
        }
        config = {
          nic_parent = "k8sbr0"
          cpu        = "2"
          memory     = "4GiB"
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
        distro       = "almalinux9"
        network_config = {
          "ipv4.address" = "10.150.10.71"
        }
        config = {
          nic_parent = "k8sbr0"
          cpu        = "2"
          memory     = "4GiB"
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
      }
    ]
  }
]

