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
          size = "9GiB"
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
    ]
  }
]
