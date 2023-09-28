{ workspace, name, ... }:
let
  pwd = builtins.toPath (builtins.getEnv "PWD");
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
  sops.validateSopsFiles = false;
  sops.defaultSopsFile = "${pwd}/secrets/zfs_keyfile.yaml";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;
  sops.secrets."${name}.${workspace}.test" = { };
}

