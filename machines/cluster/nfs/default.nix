{
  # imports = [./brbd.nix ./nfs.nix ./pacemaker.nix];

  virtualisation = {
    lxc.enable = true;
    lxd = {
      enable = true;
      recommendedSysctlSettings = true;
    };
  };
  networking.firewall.enable = false;
}
