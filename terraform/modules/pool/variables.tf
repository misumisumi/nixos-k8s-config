variable "pools" {
  type = set(
    object(
      {
        name        = string
        size        = string
        volume_size = optional(string, null)
      }
    )
  )
  description = "Strage pool propaties for ceph"
}
