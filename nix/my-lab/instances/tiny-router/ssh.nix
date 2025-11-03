{
  lib,
  user,
  pkgs,
  config,
  ...
}:
{
  environment.pathsToLink = [ "/share/bash-completion" ];
  programs.bash = {
    completion.enable = true;
    enableLsColors = true;
    vteIntegration = true;
  };

  users.users."${user}" = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [
      "wheel"
    ];
    initialHashedPassword = lib.mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
  };
  users.users.root.initialHashedPassword = lib.mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      StrictHostKeyChecking = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      PasswordAuthentication = false;
      ChallengeResponseAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  system.activationScripts.sshActivatioinAction.text =
    let
      # dnsmasq@<hoge>.serviceがProctectHome=yesなので/home以下の
      SSH_DIR = "${config.users.users."nixos".home}/.ssh";
    in
    ''
      # For tftp of dnsmasq
      if [ ! -d ${SSH_DIR} ]; then
        mkdir -m 744 ${SSH_DIR}
      fi
      if [ ! -f ${SSH_DIR}/authorized_keys ]; then
        touch ${SSH_DIR}/authorized_keys
        chmod 600 ${SSH_DIR}/authorized_keys
      fi
      if [ ! -f ${SSH_DIR}/id_ed25519.pub ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -C "$(whoami)@$(hostname)-$(date -I)" -f ${SSH_DIR}/id_ed25519
      fi
      chown -R ${user}:users ${SSH_DIR}
    '';
}
