{
  lib,
  user,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  users.users."${user}".initialPassword = mkForce "nixos";
  users.users.root.initialPassword = mkForce "nixos";

  system.activationScripts.sshActivatioinAction.text =
    let
      homeDir = "${config.users.users.${user}.home}";
    in
    ''
      if [ ! -d ${homeDir}/.ssh ]; then
        mkdir -m 700 ${homeDir}/.ssh
      fi
      if [ ! -f ${homeDir}/.ssh/id_ed25519.pub ]; then
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -C "$(whoami)@$(hostname)-$(date -I)" -f ${homeDir}/.ssh/id_ed25519
      fi
      chown ${user}:users -R ${homeDir}/.ssh
    '';
}
