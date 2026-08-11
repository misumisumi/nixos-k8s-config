compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    pools = [
      {
        name = "fake-switch"
        config = {
          size = "4GiB"
        }
      },
    ]
    volumes = []
  }
]
