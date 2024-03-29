# Default normal user config
{ config
, lib
, hostname
, user
, pkgs
, ...
}: {
  environment.pathsToLink = [ "/share/bash-completion" ];
  programs.bash = {
    enableCompletion = true;
    enableLsColors = true;
    vteIntegration = true;
    blesh.enable = true;
    interactiveShellInit = ''
      bind 'set editing-mode vi'
    '';
  };

  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "wheel" "uucp" "kvm" "input" "audio" "video" "lxd" ];
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
  } // lib.optionalAttrs (builtins.hasAttr "password" config.sops.secrets) {
    hashedPasswordFile = config.sops.secrets.password.path;
  } // lib.optionalAttrs (! builtins.hasAttr "password" config.sops.secrets) {
    password = "nixos";
  };
  users.users.root.initialHashedPassword = "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
}
