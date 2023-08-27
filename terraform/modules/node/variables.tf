variable "nodes" {
  type = set(
    object({
      name       = string
      target     = optional(string, null)
      type       = string
      ip_address = string
      devices = set(
        object({
          name         = string
          type         = string
          content_type = optional(string, "filesystem")
          properties   = map(string)
      }))
    })
  )
  description = "Name to give to each nodes"
}

variable "node_config" {
  type = object({
    cpu            = number
    memory         = string
    nic_parent     = string
    boot_autostart = optional(bool, true)
    root_block     = optional(string, "loop0")
    root_size      = optional(string, null)
  })
  description = "Node config"
}
