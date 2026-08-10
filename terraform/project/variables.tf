variable "remote_hosts" {
  type = list(
    object({
      name    = optional(string, null)
      address = optional(string, null)
    })
  )
  default = []
}

variable "projects" {
  type = list(
    object({
      name          = string
      remote        = optional(string, "local")
      description   = optional(string)
      force_destroy = optional(bool, false)
      config = optional(map(bool), {
        "features.storage.volumes" = false
        "features.images"          = false
        "features.profiles"        = false
        "features.storage.buckets" = false
      })
    })
  )
}
