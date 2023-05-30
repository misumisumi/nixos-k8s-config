variable "pool_propaties" {
  type        = set(map(string))
  description = "Strage pool propaties for ceph"
  default = [
    {
      "name" = "worker1"
      "size" = "4GiB"
    },
    {
      "name" = "worker2"
      "size" = "4GiB"
    },
  ]
}