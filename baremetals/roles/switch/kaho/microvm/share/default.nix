{ config, user, ... }:
{
  imports = [
    ../../../../share/settings/users.nix
  ];

  system = {
    stateVersion = config.system.nixos.release;
    # NixOS settings
    autoUpgrade = {
      # Allow auto update
      enable = false;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  users.users = {
    ${user}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHk5O7TU6kg/BiUeUoYkow1PMsDn+HW/+scedNZouZbf renako@microvm"
    ];
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHk5O7TU6kg/BiUeUoYkow1PMsDn+HW/+scedNZouZbf renako@microvm"
    ];
  };
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    startWhenNeeded = false;
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = true;
      X11Forwarding = false;
      PermitRootLogin = "yes";
    };
  };
}
