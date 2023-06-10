{writeShellScriptBin}: {
  init_lxd = writeShellScriptBin "init_lxd" ''
    lxd init --auto --storage-backend=btrfs --storage-create-loop=64
  '';
  init_remote_lxd = writeShellScriptBin "init_remote_lxd" ''
    colmena exec --on @hosts -- lxd init --auto --storage-backend=btrfs --storage-create-loop=64
    colmena exec --on @hosts -- lxc config set core.https_address '[::]'
    colmena exec --on @hosts -- lxd config trust add --name colmena

    jq -r ".hosts[].name" hosts.json | while read target
    do
      echo "''${target}'s token"
      ssh -F ./ssh_config ''${target} lxc config trust list-tokens --format=json | jq -r '.[] | select(.ClientName == "colmena").Token'
      echo "\n"
    done
  '';
  copy_img2lxd = writeShellScriptBin "copy_img2lxd" ''
    ALIAS_CONTAINER="nixos/lxc-container"
    ALIAS_VM="nixos/lxc-virtual-machine"

    jq -r ".hosts[].name" hosts.json | while read target
    do
        echo "Copy NixOS images to ''${target}"
        lxc image copy --mode=relay ''${ALIAS_CONTAINER} ''${target}: --alias ''${ALIAS_CONTAINER}
        lxc image copy --mode=relay ''${ALIAS_VM} ''${taget}: --alias ''${ALIAS_VM}
    done
  '';
}