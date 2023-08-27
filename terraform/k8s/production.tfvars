compornents = [
  {
    tag = "etcd"
    nodes = [
      {
        name = "etcd1"
      },
      {
        name = "etcd2"
      },
      {
        name = "etcd3"
      },
    ]
    node_config = {
      cpu        = "2"
      memory     = "2GiB"
      nic_parent = "br0"
    }
  },
  {
    tag = "controll"
    nodes = [
      {
        name = "controlplane1"
      },
      {
        name = "controlplane2"
      },
      {
        name = "controlplane3"
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
        name = "worker1"
        type = "virtual-machine"
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
        name = "worker2"
        type = "virtual-machine"
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
        name = "worker3"
        type = "virtual-machine"
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
      nic_parent = "br0"
      root_size = "16GiB"
    }
  },
  {
    tag = "load_balancer",
    nodes = [
      { name = "loadbalancer1"
      },
      { name = "loadbalancer2"
      },
    ]
    node_config = {
      cpu    = "2"
      memory = "2GiB"
      nic_parent = "br0"
    }
  },
]
pools = [
  {
    name = "ceph"
    size = "9GiB"
  },
]