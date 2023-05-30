etcd_instances = [
  {
    name       = "etcd1"
    ip_address = "10.150.10.10"
  },
  {
    name       = "etcd2"
    ip_address = "10.150.10.11"
  },
  {
    name       = "etcd3"
    ip_address = "10.150.10.12"
  },
]
etcd_RD = {
  cpu        = "2"
  memory     = "2GiB"
}

control_plane_instances = [
  {
    name       = "controlplane1"
    ip_address = "10.150.10.20"
  },
  {
    name       = "controlplane2"
    ip_address = "10.150.10.21"
  },
  {
    name       = "controlplane3"
    ip_address = "10.150.10.22"
  },
]
control_plane_RD = {
  cpu        = "2"
  memory     = "2GiB"
}
worker_instances = [
  {
    name       = "worker1"
    ip_address = "10.150.10.30"
  },
  {
    name       = "worker2"
    ip_address = "10.150.10.31"
  },
]
worker_RD = {
  cpu        = "2"
  memory     = "2GiB"
}
load_balancer_instances = [
  { name       = "loadbalancer1"
    ip_address = "10.150.10.40"
  },
  { name       = "loadbalancer2"
    ip_address = "10.150.10.41"
  },
]
load_balancer_RD = {
  cpu        = "2"
  memory     = "2GiB"
}