compornents = [
  {
    remote = "local"
    profiles = [
      { tag       = "controlplane"
        root_pool = "instances"
      },
      { tag       = "etcd"
        root_pool = "instances"
      },
      { tag       = "loadbalancer"
        root_pool = "instances"
      },
      { tag       = "worker"
        root_pool = "instances"
      },
    ]
    instances = [
      {
        name = "controlplane1"
        network_config = {
          "ipv4.address" = "10.150.10.20"
        }
        config = {
          nic_parent = "k8sbr0"
        }
      },
      {
        name = "controlplane2"
        network_config = {
          "ipv4.address" = "10.150.10.21"
        }
        config = {
          nic_parent = "k8sbr0"
        }
      },
      {
        name = "controlplane3"
        network_config = {
          "ipv4.address" = "10.150.10.22"
        }
        config = {
          nic_parent = "k8sbr0"
        }
      },
      {
        name = "etcd1"
        network_config = {
          "ipv4.address" = "10.150.10.31"
        }
        config = {
          nic_parent = "k8sbr0"
        }
        devices = [
          {
            name   = "etcd"
            create = false
            type   = "disk"
            properties = {
              pool   = "etcd"
              source = "etcd1"
              path   = "/var"
            }
          }
        ]
      },
      {
        name = "etcd2"
        network_config = {
          "ipv4.address" = "10.150.10.32"
        }
        config = {
          nic_parent = "k8sbr0"
        }
        devices = [
          {
            name   = "etcd"
            create = false
            type   = "disk"
            properties = {
              pool   = "etcd"
              source = "etcd2"
              path   = "/var"
            }
          }
        ]
      },
      {
        name = "etcd3"
        network_config = {
          "ipv4.address" = "10.150.10.33"
        }
        config = {
          nic_parent = "k8sbr0"
        }
        devices = [
          {
            name   = "etcd"
            create = false
            type   = "disk"
            properties = {
              pool   = "etcd"
              source = "etcd3"
              path   = "/var"
            }
          }
        ]
      },
      {
        name = "loadbalancer1"
        network_config = {
          "ipv4.address" = "10.150.10.41"
        }
        config = {
          nic_parent = "k8sbr0"
        }
      },
      {
        name = "loadbalancer2"
        network_config = {
          "ipv4.address" = "10.150.10.42"
        }
        config = {
          nic_parent = "k8sbr0"
        }
      },
      {
        name = "loadbalancer3"
        network_config = {
          "ipv4.address" = "10.150.10.43"
        }
        config = {
          nic_parent = "k8sbr0"
        }
      },
      {
        name         = "worker1"
        machine_type = "virtual-machine"
        network_config = {
          "ipv4.address" = "10.150.10.51"
        }
        config = {
          nic_parent = "k8sbr0"
        }
        devices = [
          {
            name = "ceph"
            type = "disk"
            properties = {
              pool   = "ceph"
              source = "ceph1"
            }
          }
        ]
      },
      {
        name         = "worker2"
        machine_type = "virtual-machine"
        network_config = {
          "ipv4.address" = "10.150.10.52"
        }
        config = {
          nic_parent = "k8sbr0"
        }
        devices = [
          {
            name = "ceph"
            type = "disk"
            properties = {
              pool   = "ceph"
              source = "ceph2"
            }
          }
        ]
      },
      {
        name         = "worker3"
        machine_type = "virtual-machine"
        network_config = {
          "ipv4.address" = "10.150.10.53"
        }
        config = {
          nic_parent = "k8sbr0"
        }
        devices = [
          {
            name = "ceph"
            type = "disk"
            properties = {
              pool   = "ceph"
              source = "ceph3"
            }
          }
        ]
      }
    ]
  }
]

