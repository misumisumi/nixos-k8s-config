network = {
  name         = "k8sbr0"
  ipv4_address = "10.150.10.1/24"
}
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
              pool   = "nfs"
              source = "nfs1"
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