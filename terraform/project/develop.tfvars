projects = [
  {
    name        = "homelab-dev"
    description = "Development project for homelab"
    config = {
      "features.images"          = false
      "features.networks"        = false
      "features.networks.zones"  = false
      "features.profiles"        = false
      "features.storage.volumes" = false
      "features.storage.buckets" = false
    }
  },
  {
    name        = "homelab-test"
    description = "Test project for homelab"
    config = {
      "features.images"          = false
      "features.networks"        = false
      "features.networks.zones"  = false
      "features.profiles"        = false
      "features.storage.volumes" = false
      "features.storage.buckets" = false
    }
  },
  {
    name        = "homelab-prod"
    description = "Production project for homelab"
    config = {
      "features.images"          = false
      "features.networks"        = false
      "features.networks.zones"  = false
      "features.profiles"        = false
      "features.storage.volumes" = false
      "features.storage.buckets" = false
    }
  }
]
