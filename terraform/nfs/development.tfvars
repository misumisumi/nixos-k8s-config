compornents = [
  {
    remote = "dev1"
    profiles = [
      {
        tag       = "nfs"
        root_pool = "default"
      }
    ]
    instances = [
      {
        name         = "nfs1"
        machine_type = "virtual-machine"
        image        = "almalinux/9/virtual-machine"
        config = {
          cpu    = "2"
          memory = "4GiB"
        }
        network_config = {
          parent = "br0"
          hwaddr = "00:16:3e:4b:4e:87"
        }
        devices = [
          {
            name = "nfs"
            type = "disk"
            properties = {
              source = "/dev/sda"
            }
          }
        ]
      }
    ]
  },
  {
    remote = "dev2"
    profiles = [
      {
        tag       = "nfs"
        root_pool = "default"
      }
    ]
    instances = [
      {
        name         = "nfs2"
        machine_type = "virtual-machine"
        image        = "almalinux/9/virtual-machine"
        config = {
          cpu    = "2"
          memory = "4GiB"
        }
        network_config = {
          parent = "br0"
          hwaddr = "00:16:3e:e9:d9:72"
        }
        devices = [
          {
            name = "nfs"
            type = "disk"
            properties = {
              source = "/dev/sda"
            }
          }
        ]
      }
    ]
  }
]

