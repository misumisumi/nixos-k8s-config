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
      tag = string
      instances = set(
        object({
          name         = string
          remote       = optional(string, null)
          network_config = optional(map(any))
          devices = optional(set(
            object({
              name         = string
              type         = string
              content_type = optional(string, "filesystem")
              properties   = map(string)
            })
          ))
        })
      )
      instance_config = map(any)
      instance_root_config = optional(map(any), {
        path = "/"
      })
    })
  )
  description = "Name and some config for instances to spawn"
}

