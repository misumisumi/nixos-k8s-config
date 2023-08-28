network = {
  name         = "k8sbr0"
  ipv4_address = "10.150.10.1/24"
}
compornents = [
  {
    tag = "etcd"
    instances = [
      { name = "etcd1" },
      { name = "etcd2" },
      { name = "etcd3" },
    ]
    instance_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  },
  {
    tag = "controlplane"
    instances = [
      { name = "controlplane1" },
      { name = "controlplane2" },
      { name = "controlplane3" },
    ]
    instance_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  },
  {
    tag = "worker",
    instances = [
      {
        name = "worker1"
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
    instance_config = {
      cpu       = "4"
      memory    = "8GiB"
      root_size = "16GiB"
    }
  },
  {
    tag = "loadbalancer",
    instances = [
      { name = "loadbalancer1" },
      { name = "loadbalancer2" },
    ]
    instance_config = {
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
]
