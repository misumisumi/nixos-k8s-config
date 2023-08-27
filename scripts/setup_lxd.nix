{ writeShellScriptBin }: {
  init_lxd = writeShellScriptBin "init_lxd" ''
    lxd init --auto --storage-backend=btrfs --storage-create-loop=64
  '';
  add_remote_lxd = writeShellScriptBin "add_remote_lxd" ''
    colmena exec --on @hosts --impure -- lxd init --auto --storage-backend=btrfs --storage-create-loop=64
    colmena exec --on @hosts --impure -- lxc config set core.https_address '[::]'
    colmena exec --on @hosts --impure -- lxc config trust add --name colmena

    declare -A remotes=()
    jq -c ".hosts[]" config.json | while read target
    do
      lxc remote add ''$(echo ''${target} | jq -r '.name') \
        `ssh -n root@''$(echo "''${target}" | jq -r '.ip_address') lxc config trust list-tokens --format=json | jq -r '.[] | select(.ClientName == "colmena").Token'`
    done
  '';
  copy_img2lxd = writeShellScriptBin "copy_img2lxd" ''
    ALIAS_CONTAINER="nixos/lxc-container"
    ALIAS_VM="nixos/lxc-virtual-machine"

    jq -r ".hosts[].name" config.json | while read target
    do
        echo "Copy NixOS images to ''${target}"
        lxc image copy --mode=relay ''${ALIAS_CONTAINER} ''${target}: --alias ''${ALIAS_CONTAINER}
        lxc image copy --mode=relay ''${ALIAS_VM} ''${taget}: --alias ''${ALIAS_VM}
    done
  '';
}
