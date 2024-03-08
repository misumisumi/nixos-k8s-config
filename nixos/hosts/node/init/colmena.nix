{ lib
, pkgs
, hostname
, tag
, group
, ...
}:
let
  inherit (import ../../../../utils/hosts.nix { inherit tag; }) ipv4_address;
  pwd = /. + builtins.getEnv "PWD";
  getKeys = filenames: builtins.filter (f: builtins.pathExists "/etc/secrets/${tag}/initrd/${f}") filenames;

  hostKeys = getKeys [
    "ssh_host_ed25519_key"
    "ssh_host_ed25519_key.pub"
    "ssh_host_rsa_key"
    "ssh_host_rsa_key.pub"
  ];
  mkHostKeys = filename: {
    keyFile = "/etc/secrets/${tag}/initrd/${filename}";
    destDir = "/etc/secrets/${tag}/initrd";
    user = "root";
    permissions = "0600";
  };
in
{
  deployment = {
    tags = [ group tag hostname ];
    targetHost = ipv4_address;
    keys = builtins.listToAttrs (builtins.map (key: { name = key; value = mkHostKeys key; }) hostKeys);
  };
}
