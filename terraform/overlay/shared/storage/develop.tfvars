compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    pools = [
      {
        name = "shared"
        config = {
          size = "8GiB"
        }
      },
    ]
    volumes = []
  }
]
