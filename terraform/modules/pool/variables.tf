variable "pools" {
  type = set(
    object(
      {
        name = string
        size = string
      }
    )
  )
  description = "Strage pool propaties for ceph"
}