nodes = [
  {
    name = "devnode1"
    config = {
      storage_pool = "pool4devnode"
      cpu_mode     = "host-passthrough"
      memory       = 8192
    }
    network = {
      bridge      = "br1"
      mac_address = "2a:79:46:21:9c:66"
      addresses   = ["192.168.101.47"]
    }
    disks = [
      {
        name         = "disk1A.qcow2",
        storage_pool = "pool4devnode"
        size         = 2147483648
      },
      {
        name         = "disk1B.qcow2",
        storage_pool = "pool4devnode"
        size         = 2147483648
      },
      {
        name         = "disk1C.qcow2",
        storage_pool = "pool4devnode"
        size         = 2147483648
      }
    ]
  },
  {
    name = "devnode2"
    config = {
      storage_pool = "pool4devnode"
      cpu_mode     = "host-passthrough"
      memory       = 8192
    }
    network = {
      bridge      = "br1",
      mac_address = "ec:13:a5:b4:22:8b",
      addresses   = ["192.168.101.48"]
    }
    disks = [
      {
        name         = "disk2A.qcow2",
        storage_pool = "pool4devnode"
        size         = 2147483648
      },
      {
        name         = "disk2B.qcow2",
        storage_pool = "pool4devnode"
        size         = 2147483648
      },
      {
        name         = "disk2C.qcow2",
        storage_pool = "pool4devnode"
        size         = 2147483648
      }
    ]
  },
  {
    name = "devnode3"
    config = {
      storage_pool = "pool4devnode"
      cpu_mode     = "host-passthrough"
      memory       = 8192
    }
    network = {
      bridge      = "br1",
      mac_address = "6a:f3:82:d5:b3:fe",
      addresses   = ["192.168.101.49"]
    }
    disks = [
      {
        name         = "disk3A.qcow2"
        storage_pool = "pool4devnode"
        size         = 2147483648
      },
      {
        name         = "disk3B.qcow2"
        storage_pool = "pool4devnode"
        size         = 2147483648
      },
      {
        name         = "disk3C.qcow2"
        storage_pool = "pool4devnode"
        size         = 2147483648
      }
    ]
  }
]

