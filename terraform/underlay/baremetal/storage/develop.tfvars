# For k8s on incus
compornents = [
  {
    project = "homelab-dev"
    pools = [
      {
        name = "baremetal"
        config = {
          size = "64GiB"
        }
      },
      {
        name = "linstor"
        config = {
          size = "128GiB"
        }
      },
    ]
    volumes = [
      {
        name         = "linstor1"
        pool         = "linstor"
        content_type = "block"
        config = {
          size = "64GiB"
        }
      },
      {
        name         = "linstor2"
        pool         = "linstor"
        content_type = "block"
        config = {
          size = "64GiB"
        }
      },
    ]
  },
]
