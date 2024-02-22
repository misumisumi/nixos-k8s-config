compornents = [
  {
    remote = "local"
    profiles = [
      {
        tag       = "nfs"
        root_pool = "instance"
      }
    ]
    instances = [
      {
        name = "netboot1"
        config = {
          nic_parent = "br0"
          cpu        = "2"
          memory     = "2GiB"
        }
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
  }
]

