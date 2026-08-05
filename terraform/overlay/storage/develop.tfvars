# For k8s on VM and container on incus
compornents = [
  {
    remote = "local"
    pools = [
      {
        name = "instances"
        config = {
          size = "64GiB"
        }
      },
      {
        name = "ceph"
        config = {
          size = "64GiB"
        }
      },
      {
        name   = "etcd"
        driver = "dir"
        config = {
          source = "/var/lib/nocow/"
          # source = "/tmp/incus"
        }
      },
      {
        name = "piraeus"
        config = {
          size = "64GiB"
        }
      },
      {
        name = "vault"
        config = {
          size = "6GiB"
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
        name         = "vault1"
        pool         = "vault"
        content_type = "block"
        config = {
          size = "2GiB"
        }
      },
      {
        name         = "vault2"
        pool         = "vault"
        content_type = "block"
        config = {
          size = "2GiB"
        }
      },
      {
        name         = "vault3"
        pool         = "vault"
        content_type = "block"
        config = {
          size = "2GiB"
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
        name         = "ceph1-meta"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "2GiB"
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
        name         = "ceph2-meta"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "2GiB"
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
        name         = "ceph3-meta"
        pool         = "ceph"
        content_type = "block"
        config = {
          size = "2GiB"
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
