# network = {
#   name         = "netbootbr0"
#   ipv4_address = "10.150.20.1/24"
# }
compornents = [
  {
    tag = "netboot"
    instances = [
      {
        name = "netboot1"
        devices = [
          {
            name = "http"
            type = "proxy"
            properties = {
              # Listen on LXD host's TCP port 80
              listen = "tcp:0.0.0.0:80"
              # And connect to the instance's TCP port 80
              connect = "tcp:127.0.0.1:80"
            }
          }
        ]
      }
    ]
    instance_config = {
      cpu        = "2"
      memory     = "2GiB"
      nic_parent = "br0"
      vlan       = "10"
    }
  }
]