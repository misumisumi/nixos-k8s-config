# Default normal user config
{
  lib,
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
    # shell = "${rbash}/bin/rbash";
    shell = pkgs.bashInteractive;
    extraGroups = [ ];
    initialHashedPassword = lib.mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
  };
  users.users.root.initialHashedPassword = lib.mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
}
