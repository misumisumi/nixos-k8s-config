compornents = [
  {
    tag = "nfs"
    instances = [
      {
        name         = "nfs1"
        network_config = {
          "ipv4.address" = "10.150.10.70"
        }
        devices = [
          {
            name         = "nfs"
            type         = "disk"
            properties = {
              pool   = "nfs"
              source = "nfs1"
            }
          }
        ]
      },
      {
        name         = "nfs2"
        network_config = {
          "ipv4.address" = "10.150.10.71"
        }
        devices = [
          {
            name         = "nfs"
            type         = "disk"
            properties = {
              pool   = "nfs"
              source = "nfs2"
            }
          }
        ]
      }
    ]
    instance_config = {
      cpu          = "2"
      memory       = "4GiB"
      nic_parent   = "k8sbr0"
      machine_type = "virtual-machine"
      image        = "almalinux9"
    }
  }
]

