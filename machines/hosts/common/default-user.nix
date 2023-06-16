# Default normal user config
{pkgs, ...}: {
  programs.bash = {
    enableCompletion = false;
  };
  users.users.cardinal = {
    isNormalUser = true;
    shell = pkgs.bash;
    initialHashedPassword = "$y$j9T$WK.ICvT6LkzmVlsCw6Zmu/$hjxhEDbbbMNiSRy58UqbQ5HjDj19CaGB2/5bi9lrB7/";
    extraGroups = ["wheel" "kvm" "input" "lxd"];
    useDefaultShell = true;
    subUidRanges = [
      # Using rootless container
      {
        count = 100000;
        startUid = 300000;
      }
    ];
    subGidRanges = [
      {
        count = 100000;
        startGid = 300000;
      }
    ];
  };

  security.sudo.wheelNeedsPassword = true; # User does need to give password when using sudo.
}