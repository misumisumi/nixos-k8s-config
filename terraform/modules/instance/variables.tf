variable "tag" {
  type        = string
  description = "Tag to identify this instance"
}

variable "set_ip_address" {
  type    = bool
  default = false
}

variable "instances" {
  type = set(
    object({
      name   = string
      remote = optional(string, "")
      devices = set(
        object({
          name         = string
          type         = string
          content_type = optional(string, "filesystem")
          properties   = map(string)
      }))
    })
  )
  description = "Name to give to each instances"
}

variable "instance_config" {
  type = object({
    cpu            = number
    memory         = string
    nic_parent     = string
    boot_autostart = optional(bool, true)
    root_block     = optional(string, "loop0")
    root_size      = optional(string, null)
  })
  description = "instance config"
}