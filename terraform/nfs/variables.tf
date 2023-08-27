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
          name       = string
          target     = optional(string, null)
          type       = optional(string, "container")
          ip_address = optional(string, null)
          devices = optional(set(
            object({
              name         = string
              type         = string
              content_type = optional(string, "filesystem")
              properties   = map(string)
            })
          ), [])
        })
      )
      instance_config = object({
        cpu        = optional(number, 2)
        memory     = optional(string, "1GiB")
        nic_parent = optional(string, "k8sbr0")
        root_size  = optional(string, null)
      })
    })
  )
  description = "Name and some config for instances to spawn"
}

variable "pools" {
  type        = set(any)
  description = "Strage pool propaties"
  default     = []
}
