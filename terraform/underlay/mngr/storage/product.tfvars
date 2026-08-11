# For k8s on incus
compornents = [
  {
    project = "homelab-prod"
    pools = [
      {
        name = "prod-mngr"
        config = {
          size = "8GiB"
        }
      },
    ]
    volumes = []
  },
]
