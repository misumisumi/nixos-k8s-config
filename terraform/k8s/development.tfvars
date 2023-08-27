compornents = [
  {
    tag = "etcd"
    nodes = [
      {
        name       = "etcd1"
        ip_address = "10.150.10.10"
      },
      {
        name       = "etcd2"
        ip_address = "10.150.10.11"
      },
      {
        name       = "etcd3"
        ip_address = "10.150.10.12"
      },
    ]
    node_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  },
  {
    tag = "controll"
    nodes = [
      {
        name       = "controlplane1"
        ip_address = "10.150.10.20"
      },
      {
        name       = "controlplane2"
        ip_address = "10.150.10.21"
      },
      {
        name       = "controlplane3"
        ip_address = "10.150.10.22"
      },
    ]
    node_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  },
  {
    tag = "worker",
    nodes = [
      {
        name       = "worker1"
        type       = "virtual-machine"
        ip_address = "10.150.10.30"
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "ceph"
              source = "ceph1"
            }
          }
        ]
      },
      {
        name       = "worker2"
        type       = "virtual-machine"
        ip_address = "10.150.10.31"
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "ceph"
              source = "ceph2"
            }
          }
        ]
      },
      {
        name       = "worker3"
        type       = "virtual-machine"
        ip_address = "10.150.10.32"
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "ceph"
              source = "ceph3"
            }
          }
        ]
      }
    ]
    node_config = {
      cpu       = "4"
      memory    = "8GiB"
      root_size = "16GiB"
    }
  },
  {
    tag = "load_balancer",
    nodes = [
      { name       = "loadbalancer1"
        ip_address = "10.150.10.40"
      },
      { name       = "loadbalancer2"
        ip_address = "10.150.10.41"
      },
    ]
    node_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  },
  {
    tag = "nfs"
    nodes = [
      {
        name       = "nfs1"
        type       = "virtual-machine"
        ip_address = "10.150.10.60"
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
        ip_address = "10.150.10.61"
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
    name = "ceph"
    size = "9GiB"
  },
  {
    name = "nfs"
    size = "4GiB"
  }
]