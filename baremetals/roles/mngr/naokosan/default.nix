{
  lib,
  inputs,
  modulesPath,
  hostSecretPath,
  hostname,
  secretPath,
  userSecretPath,
  user,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../../share/settings/locale.nix
    ../../share/settings/ssh.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ./cockpit.nix
    ./hosts.nix
    ./network.nix
    ./users.nix
  ];
  image.modules = mkForce {
    lxc = inputs.homelab-modules.nixosModules.lxc-container;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
  system = {
    activationScripts.postExtraContents = ''
      chown -R ${user}:users /home/${user}/.config
      chown -R ${user}:users /home/${user}/.ssh
      chmod 0600 /home/${user}/.ssh/id_ed25519
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
