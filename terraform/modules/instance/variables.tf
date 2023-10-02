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
      name         = string
      remote       = optional(string, "")
      ipv4_address = optional(string, null)
      cpu          = optional(number, null)
      memory       = optional(string, null)
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
    image          = optional(string, "nixos")
    machine_type   = optional(string, "container")
    vlan           = optional(number, null)
    boot_autostart = optional(bool, true)
    root_size      = optional(string, null)
    mount_fs       = optional(string, "ext4")
  })
  description = "instance config"
}

