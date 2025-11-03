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
      name       = string
      auto_start = optional(bool, true)
      remote     = optional(string, "local")
      config     = optional(any)
      devices = optional(list(
        object({
          name       = string
          type       = string
          properties = map(string)
      })), [])
      root_pool    = optional(string, "default")
      root_size    = optional(string, "8GiB")
      machine_type = optional(string, "container")
    })
  )
  default = []
}

variable "instances" {
  type = set(
    object({
      name          = string
      image         = optional(string, "nixos/23.11")
      source_remote = optional(string, "images")
      machine_type  = optional(string, "container")
      cloudinit = optional(object({
        template_file = string
        sops_file     = optional(string, "")
        hosts_file    = optional(string, "")
        vars          = optional(map(any), {})
        }), {
        template_file = ""
      })
      profiles = optional(list(any), null)
      config   = optional(map(any), {})

      networks = optional(list(map(string)), [{
        parent  = "incusbr0"
        nictype = "bridged"
      }])

      devices = list(
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
