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
      name         = string
      distro       = optional(string, "nixos")
      machine_type = optional(string, "container")
      config = object({
        cpu        = optional(number, 2)
        memory     = optional(string, "1GiB")
        nic_parent = optional(string, "incusbr0")
        mount_fs   = optional(string, "ext4")
      })
      network_config = optional(map(any))
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
