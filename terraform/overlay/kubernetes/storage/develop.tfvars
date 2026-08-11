# For k8s on VM and container on incus
compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    pools = [
      {
        name = "kubernetes"
        config = {
          size = "64GiB"
        }
      },
      {
        name = "var-k8s"
        config = {
          size = "128GiB"
        }
      },
      {
        name   = "etcd"
        driver = "dir"
        config = {
          source = "/var/lib/nocow/"
        }
      },
      {
        name = "ceph"
        config = {
          size = "32GiB"
        }
      },
      {
        name = "piraeus"
        config = {
          size = "16GiB"
        }
      },
    ]
    volumes = [
      {
        name = "etcd1"
        pool = "etcd"
      },
      {
        name = "etcd2"
        pool = "etcd"
      },
      {
        name = "etcd3"
        pool = "etcd"
      },

      {
        name         = "controlplane1"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "controlplane2"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "controlplane3"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },

      {
        name         = "worker1"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "worker2"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "worker3"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "ceph-worker1"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "ceph-worker2"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "ceph-worker3"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "piraeus-worker1"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "piraeus-worker2"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },
      {
        name         = "piraeus-worker3"
        pool         = "var-k8s"
        content_type = "block"
        config = {
          size = "16GiB"
        }
      },

      {
        name         = "ceph1-disk-01"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "ceph1-disk-02"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "ceph2-disk-01"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "ceph2-disk-02"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "ceph3-disk-01"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "ceph3-disk-02"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "piraeus-worker1-disk"
        pool         = "piraeus"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
      {
        name         = "piraeus-worker2-disk"
        pool         = "piraeus"
        content_type = "block"
        config = {
          size = "8GiB"
        }
      },
    ]
  }
]
