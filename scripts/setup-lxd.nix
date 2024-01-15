{ writeShellScriptBin }:
let
  inherit ((builtins.fromJSON (builtins.readFile ../config.json)).incus-setting) storage-backend storage-create-loop;
in
{
  mkimg4incus = writeShellScriptBin "mkimg4incus" ''
    if [ incus image list | grep -q nixos/lxc-container ]; then
      incus image delete nixos/lxc-container
    fi
    if [ incus image list | grep -q nixos/lxc-virtual-machine ]; then
      incus image delete nixos/lxc-virtual-machine
    fi
    if [ incus image list | grep -q almalinux9/lxc-container ]; then
      incus image delete almalinux9/lxc-container
    fi
    if [ incus image list | grep -q almalinux9/lxc-virtual-machine ]; then
      incus image delete almalinux9/lxc-virtual-machine
    fi
    incus image import ''$(nixos-generate -f lxc-metadata) ''$(nixos-generate -f lxc --flake ".#lxc-container") --alias nixos/lxc-container
    incus image import ''$(nixos-generate -f lxc-metadata) ''$(nixos-generate -f qcow --flake ".#lxc-virtual-machine") --alias nixos/lxc-virtual-machine
    incus image copy images:almalinux/9 local: --auto-update --alias almalinux9/lxc-container
    incus image copy images:almalinux/9 local: --auto-update --alias almalinux9/lxc-virtual-machine --vm
  '';
  init-incus = writeShellScriptBin "init-incus" ''
    incus init --auto --storage-backend="${storage-backend}" --storage-create-loop="${storage-create-loop}"
  '';
  init-remote-incus = writeShellScriptBin "init-remote-incus" ''
    colmena exec --on @hosts --impure -- incus admin init --auto --storage-backend="${storage-backend}" --storage-create-loop="${storage-create-loop}"
    colmena exec --on @hosts --impure -- incus config set core.https_address '[::]'
    colmena exec --on @hosts --impure -- incus config trust add --name colmena
  '';
  add-remote-incus = writeShellScriptBin "add-remote-incus" ''
    declare -A remotes=()
    config=$(jq -c ".hosts" config.json)
    echo "''${config}" | jq -r "keys[]" | while read target
    do
      incus remote add "''${target}" \
        $(ssh -n root@''$(echo "''${config}" | jq -r ".''${target}.ipv4_address") incus config trust list-tokens --format=json | jq -r '.[] | select(.ClientName == "colmena").Token')
    done
  '';
  copy-img2incus = writeShellScriptBin "copy-img2incus" ''
    ALIAS_CONTAINER="nixos/lxc-container"
    ALIAS_VM="nixos/lxc-virtual-machine"

    jq -r ".hosts[].name" config.json | while read target
    do
        echo "Copy NixOS images to ''${target}"
        incus image copy --mode=relay ''${ALIAS_CONTAINER} ''${target}: --alias ''${ALIAS_CONTAINER}
        incus image copy --mode=relay ''${ALIAS_VM} ''${taget}: --alias ''${ALIAS_VM}
    done
  '';
}
