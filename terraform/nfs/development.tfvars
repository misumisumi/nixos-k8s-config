compornents = [
  {
    tag = "nfs"
    nodes = [
      {
        name       = "nfs1"
        type       = "virtual-machine"
        ip_address = "10.150.10.70"
        devices = [
          {
            name         = "nfs"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "nfs"
              source = "nfs1"
            }
          }
        ]
      },
      {
        name       = "nfs2"
        type       = "virtual-machine"
        ip_address = "10.150.10.71"
        devices = [
          {
            name         = "nfs"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "nfs"
              source = "nfs2"
            }
          }
        ]
      }
    ]
    node_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  }
]

pools = [
  {
    name = "nfs"
    size = "4GiB"
  }
]