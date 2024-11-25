compornents = [
  {
    remote = "local"
    profiles = [
      {
        tag       = "ipxe-server"
        root_pool = "instances"
      }
    ]
    instances = [
      {
        name         = "ipxe-server1"
        image        = "nixos/virtual-machine"
        machine_type = "virtual-machine"
        network_config = {
          parent = "br0"
          hwaddr = "00:16:3e:06:ce:cd"
          # parent         = "k8sbr0"
          # "ipv4.address" = "10.150.10.200"
        }
        limits = {
          cpu    = "2"
          memory = "2GiB"
        }
        # devices = [
        #   {
        #     name = "http"
        #     type = "proxy"
        #     properties = {
        #       # Listen on LXD host's TCP port 80
        #       listen = "tcp:192.168.1.10:80"
        #       # And connect to the instance's TCP port 80
        #       connect = "tcp:10.150.10.200:80"
        #       nat     = true
        #     }
        #   }
        # ]
      }
    ]
  }
]

