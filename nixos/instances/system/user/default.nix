# Default normal user config
{
  config,
  lib,
  hostname,
  user,
  pkgs,
  ...
}:
let
  rbash = pkgs.runCommandNoCC "rbash-${pkgs.bashInteractive.version}" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.bashInteractive}/bin/bash $out/bin/rbash
  '';
in
{
  environment.pathsToLink = [ "/share/bash-completion" ];
  programs.bash = {
    completion.enable = true;
    enableLsColors = true;
    vteIntegration = true;
  };

  users.users."${user}" = {
    isNormalUser = true;
    shell = "${rbash}/bin/rbash";
    extraGroups = [ ];
    initialHashedPassword = "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
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
  users.users.root.initialHashedPassword = "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
}
