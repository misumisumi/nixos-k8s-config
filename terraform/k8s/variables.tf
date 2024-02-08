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
      remote = optional(string)
      profiles = set(
        object({
          tag        = string
          auto_start = optional(bool, true)
          remote     = optional(string, "local")
          config     = optional(map(any))
          root_pool  = optional(string, "default")
          root_size  = optional(string, "8GiB")
        })
      )
      instances = set(
        object({
          name         = string
          remote       = optional(string, "local")
          distro       = optional(string, "nixos")
          machine_type = optional(string, "container")
          config = object({
            cpu        = optional(number, 2)
            memory     = optional(string, "1GiB")
            nic_parent = optional(string, "incusbr0")
            mount_fs   = optional(string, "ext4")
          })
          network_config = optional(map(any))
          devices = optional(set(
            object({
              name       = string
              type       = string
              properties = map(string)
          })), [])
        })
      )
    })
  )
  description = "Name and some config for instances to spawn"
}
