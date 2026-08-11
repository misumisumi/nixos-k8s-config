# For k8s on incus
compornents = [
  {
    project = "homelab-dev"
    pools = [
      {
        name = "dev-mngr"
        config = {
          size = "16GiB"
        }
      },
    ]
    volumes = []
  },
]
