# For k8s on incus
compornents = [
  {
    pools = [
      {
        name = "baremetal"
        config = {
          size = "128GiB"
        }
      },
    ]
    volumes = []
  },
]
