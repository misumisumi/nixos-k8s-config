compornents = [
  {
    tag = "controlplane"
    instances = [
      {
        name         = "controlplane1"
        network_config = {
          "ipv4.address" = "10.150.10.20"
        }
      },
      {
        name         = "controlplane2"
        network_config = {
          "ipv4.address" = "10.150.10.21"
        }
      },
      {
        name         = "controlplane3"
        network_config = {
          "ipv4.address" = "10.150.10.22"
        }
      },
    ]
    instance_config = {
      cpu    = "2"
      memory = "2GiB"
      nic_parent = "k8sbr0"
    }
    instance_root_config = {
      path = "/"
      pool = "test"
    }
  },
  {
    tag = "etcd"
    instances = [
      {
        name         = "etcd1"
        network_config = {
          "ipv4.address" = "10.150.10.31"
        }
      },
      {
        name         = "etcd2"
        network_config = {
          "ipv4.address" = "10.150.10.32"
        }
      },
      {
        name         = "etcd3"
        network_config = {
          "ipv4.address" = "10.150.10.33"
        }
      },
    ]
    instance_config = {
      cpu    = "2"
      memory = "2GiB"
      nic_parent = "k8sbr0"
    }
    instance_root_config = {
      path = "/"
      pool = "test"
    }
  },
  {
    tag = "loadbalancer",
    instances = [
      {
        name         = "loadbalancer1"
        network_config = {
          "ipv4.address" = "10.150.10.41"
        }
      },
      {
        name         = "loadbalancer2"
        network_config = {
          "ipv4.address" = "10.150.10.42"
        }
      },
      {
        name         = "loadbalancer3"
        network_config = {
          "ipv4.address" = "10.150.10.43"
        }
      },
    ]
    instance_config = {
      cpu    = "2"
      memory = "2GiB"
      nic_parent = "k8sbr0"
    }
    instance_root_config = {
      path = "/"
      pool = "test"
    }
  },
  {
    tag = "worker",
    instances = [
      {
        name         = "worker1"
        network_config = {
          "ipv4.address" = "10.150.10.51"
        }
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            properties = {
              pool   = "ceph"
              source = "ceph1"
            }
          }
        ]
      },
      {
        name         = "worker2"
        network_config = {
          "ipv4.address" = "10.150.10.52"
        }
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            properties = {
              pool   = "ceph"
              source = "ceph2"
            }
          }
        ]
      },
      {
        name         = "worker3"
        network_config = {
          "ipv4.address" = "10.150.10.53"
        }
        devices = [
          {
            name         = "ceph"
            type         = "disk"
            properties = {
              pool   = "ceph"
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
      nic_parent = "k8sbr0"
    }
    instance_root_config = {
        size = "8GiB"
        pool = "test"
    }
  }
]

