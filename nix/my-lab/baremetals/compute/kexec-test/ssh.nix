{
  lib,
  user,
  pkgs,
  config,
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

  users.users."${user}" = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [
      "wheel"
    ];
    initialHashedPassword = mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
    openssh.authorizedKeys.keys =
      let
        inherit (builtins) getEnv readFile;
        keyFiles = [
          "${getEnv "HOME"}/.ssh/id_ed25519.pub"
          # ../../../instances/.secrets/tiny-router/ssh/id_ed25519.pub
        ];
      in
      map readFile keyFiles;
  };
  users.users.root.initialHashedPassword = mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";

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
    if [ ! -f ${homeDir}/.ssh/authorized_keys ]; then
      touch ${homeDir}/.ssh/authorized_keys
      chmod 600 ${homeDir}/.ssh/authorized_keys
    fi
    if [ ! -f ${homeDir}/.ssh/id_ed25519.pub ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -C "$(whoami)@$(hostname)-$(date -I)" -f ${homeDir}/.ssh/id_ed25519
    fi
    chown ${user}:users -R ${homeDir}/.ssh
  '';
  # systemd.services.pull-host-private-key = {
  #   description = "Pull host private SSH key from Vault";
  #   after = [
  #     "network.target"
  #     "network-online.target"
  #   ];
  #   wants = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   startLimitIntervalSec = 600;
  #   startLimitBurst = 5;
  #   serviceConfig = {
  #     Type = "oneshot";
  #     # pull private key using wget from remote ftp host named tiny-router
  #     ExecStart = "/bin/sh -c '${pkgs.curl}/bin/curl tftp://tiny-router.kexec/id_ed25519.pub >> ${homeDir}/.ssh/authorized_keys'";
  #     RemainAfterExit = "yes";
  #     RestartSec = 5;
  #     Restart = "on-failure";
  #     User = "${user}";
  #   };
  # };
}
