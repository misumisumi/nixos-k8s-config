compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "vault"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "1"
          "limits.memory" = "2GB"
        }
      },
    ]
    instances = [
      {
        name         = "vault1"
        image        = "dev/vault/vault"
        machine_type = "container"
        profiles     = ["vault"]
        networks = [
          {
            parent         = "dev-vault"
            nictype        = "bridged"
            "ipv4.address" = "172.16.11.10"
          },
        ]
        devices = [
          {
            name   = "vault"
            type   = "disk"
            create = false
            properties = {
              source = "vault1"
              pool   = "vault"
              path   = "/var/lib/vault"
            }
          },
        ]
      },
      {
        name         = "vault2"
        image        = "dev/vault/vault"
        machine_type = "container"
        profiles     = ["vault"]
        networks = [
          {
            parent         = "dev-vault"
            nictype        = "bridged"
            "ipv4.address" = "172.16.11.11"
          },
        ]
        devices = [
          {
            name   = "vault"
            type   = "disk"
            create = false
            properties = {
              source = "vault2"
              pool   = "vault"
              path   = "/var/lib/vault"
            }
          },
        ]
      },
      {
        name         = "vault3"
        image        = "dev/vault/vault"
        machine_type = "container"
        profiles     = ["vault"]
        networks = [
          {
            parent         = "dev-vault"
            nictype        = "bridged"
            "ipv4.address" = "172.16.11.12"
          },
        ]
        devices = [
          {
            name   = "vault"
            type   = "disk"
            create = false
            properties = {
              source = "vault3"
              pool   = "vault"
              path   = "/var/lib/vault"
            }
          },
        ]
      },
    ]
  }
]
