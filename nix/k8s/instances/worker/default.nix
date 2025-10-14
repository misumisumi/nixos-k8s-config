{
  imports = [
    # ../_init/settings
    ../_init/core
    ../autoresources.nix
    ./system/ceph.nix
    ./system/kubelet.nix
  ];
}
