{
  inputs,
  hostSecretPath,
  hostname,
  lib,
  modulesPath,
  secretPath,
  user,
  userSecretPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../../share/apps/bash.nix
    ../../share/apps/pkgs.nix
    ../../share/settings/cockpit.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/network.nix
    ../../share/settings/security.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ./diskless.nix
    ./incus.nix
    ./linstor.nix
    ./nftables.nix
    inputs.homelab-modules.nixosModules.vlan-aware-vxlan
  ];
  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) kexec incus-vm;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
  system = {
    activationScripts.postExtraContents = ''
      chown -R ${user}:users /home/${user}/.config
      chown -R ${user}:users /home/${user}/.ssh
    '';
    build.extraContents = [
      {
        source = secretPath + "/pki/ImCA/chain.pem";
        target = "/var/lib/certs/server/server.ca";
        mode = "0644";
      }
      {
        source = secretPath + "/pki/server/${hostname}/chain.pem";
        target = "/var/lib/certs/server/server.crt";
        mode = "0644";
      }
      {
        source = secretPath + "/pki/server/${hostname}/private/cakey.pem";
        target = "/var/lib/certs/server/server.key";
        mode = "0600";
      }
      {
        source = secretPath + "/pki/client/${user}/chain.pem";
        target = "/home/${user}/.config/incus/client.crt";
        inherit user;
        group = "users";
      }
      {
        source = secretPath + "/pki/client/${user}/private/cakey.pem";
        target = "/home/${user}/.config/incus/client.key";
        inherit user;
        group = "users";
      }
      {
        source = secretPath + "/pki/ImCA/chain.pem";
        target = "/home/${user}/.config/incus/client.ca";
        inherit user;
        group = "users";
      }
      {
        source = hostSecretPath + "/ssh/ssh_host_ed25519_key";
        target = "/etc/ssh/ssh_host_ed25519_key";
        mode = "0600";
      }
      {
        source = hostSecretPath + "/ssh/ssh_host_ed25519_key.pub";
        target = "/etc/ssh/ssh_host_ed25519_key.pub";
        mode = "0644";
      }
      {
        source = userSecretPath + "/ssh/id_ed25519.pub";
        target = "/home/${user}/.ssh/id_ed25519.pub";
        inherit user;
        group = "users";
        mode = "0644";
      }
      {
        source = userSecretPath + "/ssh/id_ed25519";
        target = "/home/${user}/.ssh/id_ed25519";
        inherit user;
        group = "users";
        mode = "0600";
      }
    ];
  };
}
