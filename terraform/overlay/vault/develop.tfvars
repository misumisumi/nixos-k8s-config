compornents = [
  {
    remote = "local"
    profiles = [
      {
        name      = "vault"
        root_pool = "instances"
        config = {
          "limits.cpu"    = "2"
          "limits.memory" = "4GB"
        }
      },
    ]
    instances = [
      {
        name         = "vault1"
        image        = "dev/nodes/vault"
        machine_type = "virtual-machine"
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
            }
          },
        ]
      },
      {
        name         = "vault2"
        image        = "dev/nodes/vault"
        machine_type = "virtual-machine"
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
            }
          },
        ]
      },
      {
        name         = "vault3"
        image        = "dev/nodes/vault"
        machine_type = "virtual-machine"
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
            }
          },
        ]
      },
    ]
  }
]
