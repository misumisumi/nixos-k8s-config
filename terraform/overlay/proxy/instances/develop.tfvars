compornents = [
  {
    remote  = "local"
    project = "homelab-dev"
    profiles = [
      {
        name      = "proxy"
        root_pool = "proxy"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "2GB"
        }
      },
    ]
    instances = [
      {
        name         = "proxy1"
        image        = "dev/proxy/proxy"
        machine_type = "container"
        profiles     = ["proxy"]
        networks = [
          {
            parent         = "dev-proxy"
            nictype        = "bridged"
            "ipv4.address" = "172.16.10.3"
          },
        ]
      },
    ]
  }
]
