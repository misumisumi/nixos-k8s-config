{ writeShellScriptBin }: let
  inherit ((builtins.fromJSON (builtins.readFile ../config.json)).lxd-setting) storage-backend storage-create-loop;
in{
  init-lxd = writeShellScriptBin "init-lxd" ''
    lxd init --auto --storage-backend="${storage-backend}" --storage-create-loop="${storage-create-loop}"
  '';
  add-remote-lxd = writeShellScriptBin "add-remote-lxd" ''
    colmena exec --on @hosts --impure -- lxd init --auto --storage-backend="${storage-backend}" --storage-create-loop="${storage-create-loop}"
    colmena exec --on @hosts --impure -- lxc config set core.https_address '[::]'
    colmena exec --on @hosts --impure -- lxc config trust add --name colmena

    declare -A remotes=()
    jq -c ".hosts[]" config.json | while read target
    do
      lxc remote add ''$(echo ''${target} | jq -r '.name') \
        `ssh -n root@''$(echo "''${target}" | jq -r '.ip_address') lxc config trust list-tokens --format=json | jq -r '.[] | select(.ClientName == "colmena").Token'`
    done
  '';
  copy-img2lxd = writeShellScriptBin "copy-img2lxd" ''
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
