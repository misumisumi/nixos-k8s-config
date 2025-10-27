variable "remote_hosts" {
  type = set(
    object({
      name    = optional(string, null)
      address = optional(string, null)
    })
  )
  default = []
}

variable "compornents" {
  type = set(
    object({
      remote  = optional(string, "local")
      project = optional(string)
      profiles = optional(set(
        object({
          name       = string
          auto_start = optional(bool, true)
          remote     = optional(string, "local")
          config     = optional(map(any))
          root_pool  = optional(string, "default")
          root_size  = optional(string, "8GiB")
        })
      ), [])
      instances = set(
        object({
          name         = string
          remote       = optional(string, "local")
          image        = optional(string, "nixos/23.11")
          machine_type = optional(string, "container")
          config       = optional(map(any), {})
          cloudinit = optional(object({
            template_file = string
            sops_file     = optional(string, "")
            hosts_file    = optional(string, "")
            vars          = optional(map(any), {})
            }), {
            template_file = ""
          })

          networks = optional(list(map(any)), [{
            parent  = "incusbr0"
            nictype = "bridged"
          }])

          devices = optional(list(
            object({
              name       = string
              type       = string
              create     = optional(bool, true)
              properties = map(string)
          })), [])
        })
      )
    })
  )
  description = "Name and some config for instances to spawn"
}
