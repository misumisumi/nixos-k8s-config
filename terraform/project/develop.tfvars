projects = [
  {
    name        = "homelab-dev"
    description = "Development project for homelab"
    config = {
      "features.images"          = true
      "features.networks"        = true
      "features.networks.zones"  = true
      "features.profiles"        = true
      "features.storage.volumes" = true
      "features.storage.buckets" = true
    }
  },
  {
    name        = "homelab-test"
    description = "Test project for homelab"
    config = {
      "features.images"          = true
      "features.networks"        = true
      "features.networks.zones"  = true
      "features.profiles"        = true
      "features.storage.volumes" = true
      "features.storage.buckets" = true
    }
  },
  {
    name        = "homelab-prod"
    description = "Production project for homelab"
    config = {
      "features.images"          = true
      "features.networks"        = true
      "features.networks.zones"  = true
      "features.profiles"        = true
      "features.storage.volumes" = true
      "features.storage.buckets" = true
    }
  }
]
