{
  inputs,
  pkgs,
  lib,
  modulesPath,
  hostname,
  user,
  isDev,
  hostSecretPath,
  secretPath,
  userSecretPath,
  ...
}:
let
  inherit (lib) mkForce optionals;
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ../../share/apps/bash.nix
    ../../share/apps/pkgs.nix
    ../../share/apps/debug.nix
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
  ];
  environment.systemPackages = with pkgs; [
    dhcpcd
    ndisc6
    mstflint-cx3-support
  ];
  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) kexec incus-vm;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };
  system = {
    activationScripts.chown = {
      deps = [ "users" ];
      text = ''
        chown -R ${user}:users /home/${user}/.config
        chown -R ${user}:users /home/${user}/.ssh
      '';
    };
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
        source = hostSecretPath + "/user_ssh/config";
        target = "/home/${user}/.ssh/config";
        inherit user;
        group = "users";
        mode = "0644";
      }
      {
        source = hostSecretPath + "/user_ssh/id_ed25519.border";
        target = "/home/${user}/.ssh/id_ed25519.border";
        inherit user;
        group = "users";
        mode = "0600";
      }
      {
        source = hostSecretPath + "/user_ssh/id_ed25519.border.pub";
        target = "/home/${user}/.ssh/id_ed25519.border.pub";
        inherit user;
        group = "users";
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
    ]
    ++ optionals (!isDev) [
      {
        source = hostSecretPath + "/wireguard/peer/oci/psk";
        target = "/var/lib/secrets/wireguard/peer/oci/psk";
        mode = "0600";
      }
      {
        source = hostSecretPath + "/wireguard/privatekey";
        target = "/var/lib/secrets/wireguard/privatekey";
        mode = "0600";
      }
    ];
  };
}
