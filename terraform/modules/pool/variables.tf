variable "remote" {
  type    = string
  default = "local"
}

variable "project" {
  type    = string
  default = null
}

variable "pools" {
  type = list(
    object(
      {
        name   = string
        driver = optional(string, "btrfs")
        config = optional(map(any), {})
      }
    )
  )
  description = "Strage pool propaties for ceph"
}
