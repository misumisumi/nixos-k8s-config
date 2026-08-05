compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "controlplane"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "2GB"
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
      {
        name      = "ceph-worker"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "4"
          "limits.memory" = "8GB"
        }
      },
      {
        name      = "piraeus-worker"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "4"
          "limits.memory" = "4GB"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
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
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.32"
          },
        ]
      },
      {
        name         = "app-worker1"
        image        = "dev/nodes/worker"
        machine_type = "virtual-machine"
        profiles     = ["worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.60"
          },
        ]
      },
      {
        name         = "app-worker2"
        image        = "dev/nodes/worker"
        machine_type = "virtual-machine"
        profiles     = ["worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.61"
          },
        ]
      },
      {
        name         = "app-worker3"
        image        = "dev/nodes/worker"
        machine_type = "virtual-machine"
        profiles     = ["worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.62"
          },
        ]
      },
      {
        name         = "ceph-worker1"
        image        = "dev/nodes/storage-worker"
        machine_type = "virtual-machine"
        profiles     = ["ceph-worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.40"
          },
        ]
        devices = [
          {
            name   = "ceph_disk_01"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph1-disk-01"
            }
          },
          {
            name   = "ceph_disk_02"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph1-disk-02"
            }
          },
          {
            name   = "ceph_meta_disk"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph1-meta"
            }
          }
        ]
      },
      {
        name         = "ceph-worker2"
        image        = "dev/nodes/storage-worker"
        machine_type = "virtual-machine"
        profiles     = ["ceph-worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.41"
          },
        ]
        devices = [
          {
            name   = "ceph_disk_01"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph2-disk-01"
            }
          },
          {
            name   = "ceph_disk_02"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph2-disk-02"
            }
          },
          {
            name   = "ceph_meta_disk"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph2-meta"
            }
          }
        ]
      },
      {
        name         = "ceph-worker3"
        image        = "dev/nodes/storage-worker"
        machine_type = "virtual-machine"
        profiles     = ["ceph-worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.42"
          },
        ]
        devices = [
          {
            name   = "ceph_disk_01"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph3-disk-01"
            }
          },
          {
            name   = "ceph_disk_02"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph3-disk-02"
            }
          },
          {
            name   = "ceph_meta_disk"
            type   = "disk"
            create = false
            properties = {
              pool   = "ceph"
              source = "ceph3-meta"
            }
          }
        ]
      },
      {
        name         = "piraeus-worker1"
        image        = "dev/nodes/storage-worker"
        machine_type = "virtual-machine"
        profiles     = ["piraeus-worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.50"
          },
        ]
        devices = [
          {
            name   = "piraeus_disk"
            type   = "disk"
            create = false
            properties = {
              pool   = "piraeus"
              source = "piraeus-worker1-disk"
            }
          }
        ]
      },
      {
        name         = "piraeus-worker2"
        image        = "dev/nodes/storage-worker"
        machine_type = "virtual-machine"
        profiles     = ["piraeus-worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.51"
          },
        ]
        devices = [
          {
            name   = "piraeus_disk"
            type   = "disk"
            create = false
            properties = {
              pool   = "piraeus"
              source = "piraeus-worker2-disk"
            }
          }
        ]
      },
      {
        name         = "piraeus-worker3"
        image        = "dev/nodes/storage-worker"
        machine_type = "virtual-machine"
        profiles     = ["piraeus-worker"]
        networks = [
          {
            parent         = "dev-overlay"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.52"
          },
        ]
      }
    ]
  }
]
