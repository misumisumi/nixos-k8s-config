compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    pools = [
      {
        name = "vault"
        config = {
          size = "16GiB"
        }
      },
    ]
    volumes = [
      {
        name = "vault1"
        pool = "vault"
        config = {
          size = "2GiB"
        }
      },
      {
        name = "vault2"
        pool = "vault"
        config = {
          size = "2GiB"
        }
      },
      {
        name = "vault3"
        pool = "vault"
        config = {
          size = "2GiB"
        }
      },
    ]
  }
]
