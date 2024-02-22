variable "remote" {
  type    = string
  default = "local"
}

variable "project" {
  type    = string
  default = null
}

variable "volumes" {
  type = set(
    object(
      {
        name         = optional(string, null)
        remote       = optional(string, null)
        pool         = optional(string, null)
        content_type = optional(string, null)
        config       = optional(map(string), {})
      }
    )
  )
  description = "Storage volume propaties for ceph"
}
