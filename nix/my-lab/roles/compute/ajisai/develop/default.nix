{
  imports = [
    ../../../share/apps/debug.nix
    ./linkage.nix
  ];
  virtualisation.incus.agent.enable = true;
}
