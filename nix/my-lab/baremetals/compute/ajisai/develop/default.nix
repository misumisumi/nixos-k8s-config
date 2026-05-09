{
  imports = [
    ../../../share/apps/debug.nix
    ../../../share/apps/wireshark.nix
    ../../../share/settings/ssh.dev.nix
    ./bgp.nix
    ./incus.nix
    ./linkage.nix
    ./network.nix
    ./users.nix
  ];
}
