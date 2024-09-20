compornents = [
  {
    remote = "local"
    profiles = [
      {
        tag       = "controlplane"
        root_pool = "instances"
      },
      {
        tag       = "etcd"
        root_pool = "instances"
      },
      {
        tag       = "loadbalancer"
        root_pool = "instances"
      },
      {
        tag       = "worker"
        root_pool = "instances"
      },
    ]
    instances = [
      {
        name  = "controlplane1"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.20"
        }
      },
      {
        name  = "controlplane2"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.21"
        }
      },
      {
        name  = "controlplane3"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.22"
        }
      },
      {
        name  = "etcd1"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.31"
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
        name  = "etcd2"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.32"
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
        name  = "etcd3"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.33"
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
        name  = "loadbalancer1"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.41"
        }
      },
      {
        name  = "loadbalancer2"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.42"
        }
      },
      {
        name  = "loadbalancer3"
        image = "nixos/container"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.43"
        }
      },
      {
        name         = "worker1"
        image        = "nixos/virtual-machine"
        machine_type = "virtual-machine"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.51"
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
        image        = "nixos/virtual-machine"
        machine_type = "virtual-machine"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.52"
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
        image        = "nixos/virtual-machine"
        machine_type = "virtual-machine"
        network_config = {
          parent         = "k8sbr0"
          "ipv4.address" = "10.150.10.53"
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

