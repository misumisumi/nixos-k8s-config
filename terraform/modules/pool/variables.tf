variable "remote" {
  type    = string
  default = "local"
}

variable "project" {
  type    = string
  default = null
}

variable "pools" {
  type = set(
    object(
      {
        name   = string
        config = map(any)
      }
    )
  )
  description = "Strage pool propaties for ceph"
}
