compornents = [
  {
    remote = "local"
    pools = [
      {
        name = "nodes"
        config = {
          size = "32GiB"
        }
      },
      {
        name = "external"
        config = {
          size = "16GiB"
        }
      },
    ]
    volumes = []
  }
]
