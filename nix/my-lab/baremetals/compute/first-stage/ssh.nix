{
  lib,
  user,
  pkgs,
  config,
  secretPath,
  ...
}:
let
  homeDir = config.users.users."nixos".home;
  inherit (lib) mkForce;
in
{
  environment.pathsToLink = [ "/share/bash-completion" ];
  programs.bash = {
    completion.enable = true;
    enableLsColors = true;
    vteIntegration = true;
  };

  users.users =
    let
      sshKeys =
        let
          inherit (builtins) getEnv readFile;
          keyFiles = [
            "${getEnv "HOME"}/.ssh/id_ed25519.pub"
            "${secretPath}/instance/tiny-router/ssh/id_ed25519.pub"
          ];
        in
        map readFile keyFiles;
    in
    {
      "${user}" = {
        isNormalUser = true;
        shell = pkgs.bashInteractive;
        extraGroups = [
          "wheel"
        ];
        initialHashedPassword = mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
        openssh.authorizedKeys.keys = sshKeys;
      };
      root = {
        initialHashedPassword = mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
        openssh.authorizedKeys.keys = sshKeys;
      };
    };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      PasswordAuthentication = false;
      ChallengeResponseAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  system.activationScripts.sshActivatioinAction.text = ''
    if [ ! -d ${homeDir}/.ssh ]; then
      mkdir -m 700 ${homeDir}/.ssh
    fi
    if [ ! -f ${homeDir}/.ssh/id_ed25519.pub ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -C "$(whoami)@$(hostname)-$(date -I)" -f ${homeDir}/.ssh/id_ed25519
    fi
    chown ${user}:users -R ${homeDir}/.ssh
  '';
}
