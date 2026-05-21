{
  self,
  inputs,
  pkgs,
  lib,
  modulesPath,
  isDev,
  hostname,
  user,
  hostSecretPath,
  secretPath,
  userSecretPath,
  ...
}:
let
  inherit (lib) mkForce optional;
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ../../share/apps/bash.nix
    ../../share/apps/pkgs.nix
    ../../share/settings/cockpit.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/network.nix
    ../../share/settings/security.nix
    ../../share/settings/ssh.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ./bgp.nix
    ./diskless.nix
    ./microvm
    ./network.nix
    ./users.nix
  ]
  ++ optional isDev ./develop;
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
  ];
  image.modules = mkForce {
    inherit (self.nixosModules) kexec;
    incus-vm = self + "/modules/incus-virtual-machine.nix";
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
  system = {
    activationScripts.chown = ''
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
