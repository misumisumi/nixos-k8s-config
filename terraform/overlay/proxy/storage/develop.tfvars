compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    pools = [
      {
        name = "proxy"
        config = {
          size = "8GiB"
        }
      },
    ]
    volumes = []
  }
]
