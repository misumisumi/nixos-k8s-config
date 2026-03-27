# For k8s on incus
compornents = [
  {
    pools = [
      {
        name = "dev-baremetal"
        config = {
          size = "256GiB"
        }
      },
    ]
    volumes = []
  },
]
