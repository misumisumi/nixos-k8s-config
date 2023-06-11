# Default normal user config
{
  pkgs,
  hostname,
  ...
}: {
  programs.bash = {
    enableCompletion = false;
  };
  users.users."${hostname}" = {
    isNormalUser = true;
    shell = pkgs.bash;
    initialHashedPassword = "$y$j9T$Wn.jPTa4eGqJ9fjcyNjkp/$vQFpXhYbCwlCXCzMbJxtRjNdEkmREnSFjVrtpUTqeMA";
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