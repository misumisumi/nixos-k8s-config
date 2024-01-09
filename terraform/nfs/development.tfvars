compornents = [
  {
    tag = "nfs"
    instances = [
      {
        name         = "nfs1"
        ipv4_address = "10.150.10.70"
        devices = [
          {
            name         = "nfs"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "dev-nfs"
              source = "nfs1"
            }
          },
          {
            name = "key"
            type = "disk"
            properties = {
              source   = "/run/user/1000/keys/nfs1"
              path     = "/etc/secrets"
              readonly = true
            }
          }
        ]
      },
      {
        name         = "nfs2"
        ipv4_address = "10.150.10.71"
        devices = [
          {
            name         = "nfs"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "dev-nfs"
              source = "nfs2"
            }
          },
          {
            name = "key"
            type = "disk"
            properties = {
              source   = "/run/user/1000/keys/nfs2"
              path     = "/etc/secrets"
              readonly = true
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

pools = [
  {
    name        = "nfs"
    size        = "5GiB"
    volume_size = "2GiB"
  }
]

