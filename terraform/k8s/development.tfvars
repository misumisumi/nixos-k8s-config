compornents = [
  {
    tag = "controlplane"
    instances = [
      {
        name         = "controlplane1"
        ipv4_address = "10.150.10.20"
      },
      {
        name         = "controlplane2"
        ipv4_address = "10.150.10.21"
      },
      {
        name         = "controlplane3"
        ipv4_address = "10.150.10.22"
      },
    ]
    instance_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  },
  {
    tag = "etcd"
    instances = [
      {
        name         = "etcd1"
        ipv4_address = "10.150.10.10"
      },
      {
        name         = "etcd2"
        ipv4_address = "10.150.10.11"
      },
      {
        name         = "etcd3"
        ipv4_address = "10.150.10.12"
      },
    ]
    instance_config = {
      cpu    = "2"
      memory = "2GiB"
    }
  },
  {
    tag = "loadbalancer",
    instances = [
      {
        name         = "loadbalancer1"
        ipv4_address = "10.150.10.30"
      },
      {
        name         = "loadbalancer2"
        ipv4_address = "10.150.10.31"
      },
      {
        name         = "loadbalancer3"
        ipv4_address = "10.150.10.32"
      },
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
        name         = "worker1"
        ipv4_address = "10.150.10.40"
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "devceph"
              source = "ceph1"
            }
          }
        ]
      },
      {
        name         = "worker2"
        ipv4_address = "10.150.10.41"
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "dev-ceph"
              source = "ceph2"
            }
          }
        ]
      },
      {
        name         = "worker3"
        ipv4_address = "10.150.10.42"
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            content_type = "block"
            properties = {
              pool   = "dev-ceph"
              source = "ceph3"
            }
          }
        ]
      }
    ]
    instance_config = {
      machine_type = "virtual-machine"
      cpu          = "4"
      memory       = "8GiB"
      root_size    = "16GiB"
    }
  }
]

