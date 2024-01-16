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
      remote       = optional(string)
      network_config = optional(map(any))
      cpu          = optional(number)
      memory       = optional(string)
      devices = set(
        object({
          name         = string
          type         = string
          properties   = map(string)
      }))
    })
  )
  description = "Name to give to each instances"
}

variable "instance_config" {
  type = object({
    cpu            = string
    memory         = string
    nic_parent     = string
    image          = optional(string, "nixos")
    machine_type   = optional(string, "container")
    vlan           = optional(string, "0")
    boot_autostart = optional(bool, true)
    mount_fs       = optional(string, "ext4")
  })
  description = "instance config"
}

variable "instance_root_config" {
  type = map(any)
  description = "instance root config"
}

