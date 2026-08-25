terraform {
  required_providers {
    null = {
      source  = "registry.opentofu.org/hashicorp/null"
      version = "~> 3.0"
    }
    external = {
      source  = "registry.opentofu.org/hashicorp/external"
      version = "~> 2.3"
    }
    time = {
      source  = "registry.opentofu.org/hashicorp/time"
      version = "~> 0.12"
    }
  }
}