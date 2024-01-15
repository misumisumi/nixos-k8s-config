{ workspace
, name
, ...
}:
let
  pwd = /. + builtins.getEnv "PWD";
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
  # sops.validateSopsFiles = false;
  sops = {
    defaultSopsFile = ../../secrets/zfs_keyfile.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # age.keyFile = "/var/lib/sops-nix/key.txt";
    # age.generateKey = true;
    secrets."${name}/${workspace}/test" = { };
  };
}

