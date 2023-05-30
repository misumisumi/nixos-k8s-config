variable "etcd_pool" {
  type        = set(map(string))
  description = "Strage pool propaties for rootfs of etcd nodes"
  default = {
    "name" = "etcd"
    "size" = "4GiB"
  }
}
variable "control_plane_pool" {
  type        = set(map(string))
  description = "Strage pool propaties for rootfs of control plane nodes"
  default = {
    "name" = "control_plane"
    "size" = "4GiB"
  }
}
variable "load_balancer_pool" {
  type        = set(map(string))
  description = "Strage pool propaties for rootfs of load_balancer nodes"
  default = {
    "name" = "load_balancer"
    "size" = "4GiB"
  }
}
variable "worker_pool" {
  type        = set(map(string))
  description = "Strage pool propaties for rootfs of worker nodes"
  default = {
    "name" = "worker"
    "size" = "4GiB"
  }
}