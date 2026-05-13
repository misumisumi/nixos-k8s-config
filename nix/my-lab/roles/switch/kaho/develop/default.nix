{
  imports = [
    ../../../share/settings/ssh.dev.nix
    ./bgp.nix
    ./microvm
    ./network.nix
    ./users.nix
  ];
  # system.build.diskSize = "10485760000"; # 10GiB
}
