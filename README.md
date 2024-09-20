# PROJECT Cardinal

<img src="logo/logo.png" width=100% height=100%>

> This repository is currently a work in progress.  
> I don't know when v1.0.0 will be reached due to the large number of tasks.  
> You can check the current tasks and progress [here](https://github.com/users/misumisumi/projects/1/views/1).

# What is this ?

This project to create a High-Available kubernetes on-premise cluster with Infurastracture as Code (IaC) in your home.  
Emphasis is placed on reproducibility, portability, and recoverability.

## Motivation

Inspired by [nixos-ha-cluster](https://github.com/justinas/nixos-ha-kubernetes), I began to build.
NixOS enables declarative node management and HA k8s cluster building.  
The differences between his project and this.

- Response to [Flakes](https://nixos.wiki/wiki/Flakes)
- Light weight nodes by LXC/Incus
- k8s environment with ingress-nginx, LoadBalancer and Rook/Ceph support
- Building HA NFS clusters as persistent volumes
- Support for building k8s on local and external physical machines
- Additional utilities

## Precautions

- I am beginner in server operation and networking.
- Often make disruptive changes.

# What product using ?

- [NixOS](https://nixos.org/): As Hypervisor and Platform of k8s
- [Colmena](https://colmena.cli.rs/unstable/): Deploy tool for NixOS
- [Terraform](https://www.terraform.io/): Management of container and virtual machine for node of k8s
- [LXC](https://linuxcontainers.org)/[LXD](https://ubuntu.com/lxd): As Nodes for k8s cluster

## Relationship

- [ansible-k8s-config](): Ansible-playbooks for apps on k8s

# Cluster Architecture (development)

- You can change resource and count of node editing `local-dev.tfvars`

| Node                   | etcd          | loadbalancer                   | nfs                  |
| ---------------------- | ------------- | ------------------------------ | -------------------- |
| description            | etcd database | proxies to the k8s API         | external volume      |
| component              | etcd          | keepalibed, haproxy, logrotate | nfs, pacemaker, brbd |
| count of node          | 3             | 2                              | 2                    |
| resouce/node (RAM/CPU) | 1GiB/2Core    | 1GiB/2Core                     | 1GiB/2Core           |

| Node                   | controlplane                                                               | worker                                |
| ---------------------- | -------------------------------------------------------------------------- | ------------------------------------- |
| description            | controlplane for k8s                                                       | worker for k8s                        |
| component              | kube-{apiserver,controller-manager,scheduler} <br> and component of worker | kubelet, kube-proxy, coredns, flannel |
| count of node          | 3                                                                          | 3                                     |
| resouce/node (RAM/CPU) | 1GiB/2Core                                                                 | 1GiB/2Core                            |
