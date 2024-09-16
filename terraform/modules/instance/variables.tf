variable "remote" {
  type    = string
  default = "local"
}

variable "project" {
  type    = string
  default = null
}

variable "profiles" {
  type = set(
    object({
      tag        = string
      auto_start = optional(bool, true)
      remote     = optional(string, "local")
      config     = map(any)
      root_pool  = optional(string, "default")
      root_size  = optional(string, "8GiB")
    })
  )
}

variable "instances" {
  type = set(
    object({
      name           = string
      image          = optional(string, "nixos/23.11")
      source_remote  = optional(string, "images")
      machine_type   = optional(string, "container")
      config         = optional(map(any), {})
      limits         = optional(map(any), {})
      network_config = optional(map(any), { parent = "incusbr0" })
      devices = set(
        object({
          name       = string
          type       = string
          create     = optional(bool, true)
          properties = map(string)
      }))
    })
  )
  description = "Name to give to each instances"
}
