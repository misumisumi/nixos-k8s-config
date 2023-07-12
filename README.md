# What is this ?

This project to create a High-Available kubernetes on-premise cluster with Infurastracture as Code (IaC) in your home.  
Reproducibility, portability, and recoverability are important.

## Motivation

Inspired by [nixos-ha-cluster](https://github.com/justinas/nixos-ha-kubernetes), we began to build.
NixOS enables declarative node management and HA k8s cluster building.  
The differences between his project and the others are as follows

- Response to [Flakes](https://nixos.wiki/wiki/Flakes)
- Light weight nodes by LXC/LXD
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

## External repository

- [ansible-k8s-config](): Ansible-playbooks for apps on k8s

# Cluster Architecture (default)

- You can change resource and count of node editing `development.tfvars`

| Node                   | etcd          | loadbalancer                   | nfs                  |
| ---------------------- | ------------- | ------------------------------ | -------------------- |
| description            | etcd database | proxies to the k8s API         | external volume      |
| component              | etcd          | keepalibed, haproxy, logrotate | nfs, pacemaker, brbd |
| count of node          | 3             | 2                              | 2                    |
| resouce/node (RAM/CPU) | 2GiB/2Core    | 2GiB/2Core                     | 2GiB/2Core           |

| Node                   | controlplane                                                               | worker                                |
| ---------------------- | -------------------------------------------------------------------------- | ------------------------------------- |
| description            | controlplane for k8s                                                       | worker for k8s                        |
| component              | kube-{apiserver,controller-manager,scheduler} <br> and component of worker | kubelet, kube-proxy, coredns, flannel |
| count of node          | 3                                                                          | 3                                     |
| resouce/node (RAM/CPU) | 2GiB/2Core                                                                 | 2GiB/2Core                            |

# Host Architecture (My physical machine)

- Physical machine for local develop

  - Storage is built smaller, but nothing can be deployed on k8s

  | Resources        | Nesessary     |
  | ---------------- | ------------- |
  | CPU              | 4Core or more |
  | Memory           | 16GiB or more |
  | LXC default pool | 56GiB or more |

- Physical machine for actual operation

  | Name      | alice | yui | strea |
  | --------- | ----- | --- | ----- |
  | CPU (C/T) | 4/4   | 4/8 | 4/4   |
  | RAM (GiB) | 8     | 32  | 16    |

# Usage (Local Development)

## 0. Prerequisites

Make sure you have the ssh public key in `~/.ssh`.  
If not, create one using `ed25519` or `rsa`.

### For NixOS

- Enable `lxc` and `lxd`
- Enable `flakes`
- lxd package of [nixpkgs]() cannot be used by VM, so external package ([lxd-nixos](https://codeberg.org/adamcstephens/lxd-nixos)) must be used
- (optional): Install [direnv](https://github.com/direnv/direnv)

```nix
{
  inputs.lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
  ...
}
---
{inputs, ...}:
{
  virtualisation = {
    lxc.enable = true;
    lxd = {
      enable = true;
      recommendedSysctlSettings = true;
      package = inputs.lxd-nixos.packages.x86_64-linux.lxd;
    };
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
```

### For Other Linux Distribusions

It has not been tested and is not supported except by NixOS, but I believe the following procedure can be used

1. Install `LXC` and `LXD`
2. Install `nix` from [official site](https://nixos.org/download.html) or your package manager
3. Edit either `~/.config/nix/nix.conf` or `/etc/nix/nix.conf` and add (details from [Nix Flakes](https://nixos.wiki/wiki/Flakes)):
   ```
   experimental-features = nix-command flakes
   ```
4. (optional): Install [direnv](https://github.com/direnv/direnv)

## 1. Setup environment

```
$ direnv allow          # If you use direnv
or $ nix develop --impure  # If you do not use direnv
$ mkenv                 # Init terraform and make workspace
$ lxd init              # 56GiB or more size for default pool
$ mkimg4lxc             # make container and VM image for lxc
```

## 2. Launch each nodes.

```
$ ter apply development
```

## 3. Deploy k8s

```
$ mkcerts                        # Generate TLS self-certificates for Kubernetes, etcd, and other daemons.
$ deploy apply k8s development
$ check_k8s                      # check_k8s
```

## 4. Destroy k8s

```
$ ter destroy development
```