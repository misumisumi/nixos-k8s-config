variable "remote" {
  type    = string
  default = "local"
}

variable "project" {
  type    = string
  default = null
}

variable "profiles" {
  type = list(
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
  type = list(
    object({
      name          = string
      image         = optional(string, null)
      source_remote = optional(string, "images")
      running       = optional(bool, true)
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

      networks = optional(list(map(string)), [{}])

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
