etcd_instances = [
  { name = "etcd1" },
  { name = "etcd2" },
  { name = "etcd3" }
]
etcd_RD = {
  cpu        = "2"
  memory     = "2GiB"
  nic_parent = "br0"
}
control_plane_instances = [
  { name = "controlplane1" },
  { name = "controlplane2" },
  { name = "controlplane3" }
]
control_plane_RD = {
  cpu        = "2"
  memory     = "2GiB"
  nic_parent = "br0"
}
worker_instances = [
  { name = "worker1" },
  { name = "worer2" }
]
worker_RD = {
  cpu        = "2"
  memory     = "2GiB"
  nic_parent = "br0"
}
load_balancer_instances = [
  { name = "loadbalancer1" },
  { name = "loadbalancer2" }
]
load_balancer_RD = {
  cpu        = "2"
  memory     = "2GiB"
  nic_parent = "br0"
}