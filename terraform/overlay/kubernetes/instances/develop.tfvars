compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    profiles = [
      {
        name      = "controlplane"
        root_pool = "kubernetes"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "6GB"
        }
      },
      {
        name      = "etcd"
        root_pool = "kubernetes"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "2GB"
        }
      },
      {
        name      = "loadbalancer"
        root_pool = "kubernetes"
      },
      {
        name      = "worker"
        root_pool = "kubernetes"
        config = {
          "limits.cpu"    = "4"
          "limits.memory" = "8GB"
        }
      },
      {
        name      = "ceph-worker"
        root_pool = "kubernetes"
        config = {
          "limits.cpu"    = "4"
          "limits.memory" = "6GB"
        }
      },
      {
        name      = "piraeus-worker"
        root_pool = "kubernetes"
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
            parent         = "dev-nodes"
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
            parent         = "dev-nodes"
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
            parent         = "dev-nodes"
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.20"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "etcd"
              source = "etcd1"
              path   = "/var/lib"
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.21"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "etcd"
              source = "etcd2"
              path   = "/var/lib"
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.22"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "etcd"
              source = "etcd3"
              path   = "/var/lib"
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.30"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "controlplane1"
            }
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.31"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "controlplane2"
            }
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.32"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "controlplane3"
            }
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.60"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "worker1"
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.61"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "worker2"
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
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.62"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "worker3"
            }
          }
        ]
      },
      {
        name         = "ceph-worker1"
        image        = "dev/nodes/ceph-worker"
        machine_type = "virtual-machine"
        profiles     = ["ceph-worker"]
        networks = [
          {
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.40"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "ceph-worker1"
            }
          },
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
          }
        ]
      },
      {
        name         = "ceph-worker2"
        image        = "dev/nodes/ceph-worker"
        machine_type = "virtual-machine"
        profiles     = ["ceph-worker"]
        networks = [
          {
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.41"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "ceph-worker2"
            }
          },
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
          }
        ]
      },
      {
        name         = "ceph-worker3"
        image        = "dev/nodes/ceph-worker"
        machine_type = "virtual-machine"
        profiles     = ["ceph-worker"]
        networks = [
          {
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.42"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "ceph-worker3"
            }
          },
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
          }
        ]
      },
      {
        name         = "piraeus-worker1"
        image        = "dev/nodes/piraeus-worker"
        machine_type = "virtual-machine"
        profiles     = ["piraeus-worker"]
        networks = [
          {
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.50"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "piraeus-worker1"
            }
          },
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
        image        = "dev/nodes/piraeus-worker"
        machine_type = "virtual-machine"
        profiles     = ["piraeus-worker"]
        networks = [
          {
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.51"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "piraeus-worker2"
            }
          },
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
        image        = "dev/nodes/piraeus-worker"
        machine_type = "virtual-machine"
        profiles     = ["piraeus-worker"]
        networks = [
          {
            parent         = "dev-nodes"
            nictype        = "bridged"
            "ipv4.address" = "172.16.100.52"
          },
        ]
        devices = [
          {
            name   = "var_lib"
            create = false
            type   = "disk"
            properties = {
              pool   = "var-k8s"
              source = "piraeus-worker3"
            }
          },
        ]
      }
    ]
  }
]
