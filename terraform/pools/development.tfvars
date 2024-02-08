compornents = [
  {
    remote = "local"
    pools = [
      {
        name = "instances"
        config = {
          size = "32GiB"
        }
      },
      {
        name = "ceph"
        config = {
          size = "9GiB"
        }
      },
      {
        name = "etcd"
        config = {
          size = "6GiB"
        }
      },
      {
        name = "nfs"
        config = {
          size = "8GiB"
        }
      }
    ]
    volumes = [
      {
        name = "etcd1"
        pool = "etcd"
        config = {
          size = "2GiB"
        }
      },
      {
        name = "etcd2"
        pool = "etcd"
        config = {
          size = "2GiB"
        }
      },
      {
        name = "etcd3"
        pool = "etcd"
        config = {
          size = "2GiB"
        }
      }
    ]
  }
]
