{ workspace, name, ... }:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
  hostKey = filename: permissions: {
    keyFile = "${pwd}/.ssh/host_keys/${workspace}/${name}";
    destDir = "/etc/ssh/";
    user = "root";
    permissions = "${permissions}";
  };
in
{
  imports = [
    ../init
    ./autoresources.nix
    ./drbd.nix
    ./nfs.nix
    # ./pacemaker.nix
    ./zfs.nix
  ];

  # ssh keys
  deployment.keys = {
    "ssh_host_rsa_key" = hostKey "ssh_host_rsa_key" "0600";
    "ssh_host_rsa_key.pub" = hostKey "ssh_host_rsa_key.pub" "0644";
    "ssh_host_ed25519_key" = hostKey "ssh_host_ed25519_key" "0600";
    "ssh_host_ed25519_key.pub" = hostKey "ssh_host_ed25519_key.pub" "0644";
  };
}