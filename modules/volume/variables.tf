variable "volumes" {
  type = set(
    object(
      {
        name = string
        pool = string
      }
    )
  )
  description = "Storage volume propaties for ceph"
}