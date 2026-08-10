# For k8s on incus
compornents = [
  {
    pools = [
      {
        name = "dev-baremetal"
        config = {
          size = "64GiB"
        }
      },
      {
        name = "dev-linstor"
        config = {
          size = "128GiB"
        }
      },
      {
        name = "dev-k8s"
        config = {
          size = "128GiB"
        }
      },
    ]
    volumes = [
      {
        name         = "linstor1"
        pool         = "dev-linstor"
        content_type = "block"
        config = {
          size = "64GiB"
        }
      },
      {
        name         = "linstor2"
        pool         = "dev-linstor"
        content_type = "block"
        config = {
          size = "64GiB"
        }
      },
      {
        name         = "linstor3"
        pool         = "dev-linstor"
        content_type = "block"
        config = {
          size = "64GiB"
        }
      },
    ]
  },
]
