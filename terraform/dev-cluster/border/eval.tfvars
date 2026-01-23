compornents = [
  {
    remote   = "local"
    profiles = []
    instances = [
      {
        name         = "border"
        image        = "mylab/border"
        machine_type = "virtual-machine"
        config = {
          "limits.cpu"    = 2
          "limits.memory" = "4GB"
        }
        networks = [
          {
            parent  = "dev-1g"
            nictype = "bridged"
          },
          {
            parent  = "dev-10g"
            nictype = "bridged"
          },
          {
            parent  = "dev-40g"
            nictype = "bridged"
          },
        ]
      },
      # {
      #   name         = "border2"
      #   image        = "mylab/border2"
      #   machine_type = "virtual-machine"
      #   config = {
      #     "limits.cpu"    = 2
      #     "limits.memory" = "4GB"
      #   }
      #   networks = [
      #     {
      #       parent  = "dev-1g"
      #       nictype = "bridged"
      #     },
      #     {
      #       parent  = "dev-10g"
      #       nictype = "bridged"
      #     },
      #     {
      #       parent  = "dev-40g"
      #       nictype = "bridged"
      #     },
      #   ]
      # },
    ]
  }
]
