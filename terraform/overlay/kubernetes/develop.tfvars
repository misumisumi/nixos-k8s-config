compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "controlplane"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "4GB"
        }
      },
      {
        name      = "etcd"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "4GB"
        }
      },
      {
        name      = "loadbalancer"
        root_pool = "instances"
      },
      {
        name      = "worker"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "4"
          "limits.memory" = "8GB"
        }
      },
    ]
    instances = [
      {
        name     = "loadbalancer1"
        image    = "dev/nodes/loadbalancer"
        profiles = ["loadbalancer"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.10"
          },
        ]
      },
      {
        name     = "loadbalancer2"
        image    = "dev/nodes/loadbalancer"
        profiles = ["loadbalancer"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.11"
          },
        ]
      },
      {
        name     = "loadbalancer3"
        image    = "dev/nodes/loadbalancer"
        profiles = ["loadbalancer"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.12"
          },
        ]
      },
      {
        name     = "etcd1"
        image    = "dev/nodes/etcd"
        profiles = ["etcd"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.20"
          },
        ]
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
        name     = "etcd2"
        image    = "dev/nodes/etcd"
        profiles = ["etcd"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.21"
          },
        ]
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
        name     = "etcd3"
        image    = "dev/nodes/etcd"
        profiles = ["etcd"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.22"
          },
        ]
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
        name         = "controlplane1"
        image        = "dev/nodes/controlplane"
        machine_type = "virtual-machine"
        profiles     = ["controlplane"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.30"
          },
        ]
      },
      {
        name         = "controlplane2"
        image        = "dev/nodes/controlplane"
        machine_type = "virtual-machine"
        profiles     = ["controlplane"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.31"
          },
        ]
      },
      {
        name         = "controlplane3"
        image        = "dev/nodes/controlplane"
        machine_type = "virtual-machine"
        profiles     = ["controlplane"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.32"
          },
        ]
      },
      {
        name         = "worker1"
        image        = "dev/nodes/worker"
        machine_type = "virtual-machine"
        profiles     = ["worker"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.40"
          },
        ]
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
        image        = "dev/nodes/worker"
        machine_type = "virtual-machine"
        profiles     = ["worker"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.41"
          },
        ]
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
        image        = "dev/nodes/worker"
        machine_type = "virtual-machine"
        profiles     = ["worker"]
        networks = [
          {
            parent         = "dev-service"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.42"
          },
        ]
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
