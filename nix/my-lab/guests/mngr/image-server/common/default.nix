{
  lib,
  modulesPath,
  self,
  specificSecretPatch,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ./dnsmasq.nix
    ./nginx.nix
    ../../../share/apps/bash
    ../../../share/settings/nix
    # ../../share/settings/ssh
    ../../../share/settings/user
    # ../../share/virtualization/container
    self.nixosModules.build
    self.nixosModules.multiple-dnsmasq
  ];

  systemd.tmpfiles.rules = [
    # "d /home/${user}/.ssh 0700 ${user} ${user} -"
    # "f /home/${user}/.ssh/id_ed25519 0600 ${user} ${user} -"
    # "f /home/${user}/.ssh/id_ed25519.pub 0644 ${user} ${user} -"
    "f /etc/ssh/ssh_host_ed25519 0600 root root -"
    "f /etc/ssh/ssh_host_ed25519_key.pub 0644 root root -"
  ];
  system.build.extraContents = [
    # {
    #   source = "${secretPath}/mngr/image-server/ssh/id_ed25519";
    #   target = "/home/${user}/.ssh/id_ed25519";
    # }
    # {
    #   source = "${secretPath}/mngr/image-server/ssh/id_ed25519.pub";
    #   target = "/home/${user}/.ssh/id_ed25519.pub";
    # }
    {
      source = specificSecretPatch + "/ssh/ssh_host_ed25519_key";
      target = "/etc/ssh/ssh_host_ed25519_key";
    }
    {
      source = specificSecretPatch + "/ssh/ssh_host_ed25519_key.pub";
      target = "/etc/ssh/ssh_host_ed25519_key.pub";
    }
  ];
  image.modules = mkForce {
    lxc = self.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
}
