{ writeShellScriptBin }:
let
  inherit ((builtins.fromJSON (builtins.readFile ../config.json)).incus-setting) storage-backend storage-create-loop;
in
{
  mkimg4incus = writeShellScriptBin "mkimg4incus" ''
    if [[ $(incus image list | grep -q nixos/container) ]]; then
      incus image delete nixos/container
    fi
    if [[ $(incus image list | grep -q nixos/virtual-machine) ]]; then
      incus image delete nixos/virtual-machine
    fi
    if [[ $(incus image list | grep -q almalinux9/container) ]]; then
      incus image delete almalinux9/container
    fi
    if [[ $(incus image list | grep -q almalinux9/virtual-machine) ]]; then
      incus image delete almalinux9/virtual-machine
    fi
    incus image import ''$(nixos-generate -f lxc-metadata) ''$(nixos-generate -f lxc --flake ".#lxc-container") --alias nixos/container
    incus image import ''$(nixos-generate -f lxc-metadata) ''$(nixos-generate -f qcow --flake ".#virtual-machine") --alias nixos/virtual-machine
    incus image copy images:almalinux/9 local: --auto-update --alias almalinux9/container
    incus image copy images:almalinux/9 local: --auto-update --alias almalinux9/virtual-machine --vm
  '';
  init-incus = writeShellScriptBin "init-incus" ''
    incus init --auto --storage-backend="${storage-backend}" --storage-create-loop="${storage-create-loop}"
  '';
  init-remote-incus = writeShellScriptBin "init-remote-incus" ''
    colmena exec --on @hosts --impure -- incus admin init --auto --storage-backend="${storage-backend}" --storage-create-loop="${storage-create-loop}"
    colmena exec --on @hosts --impure -- incus config set core.https_address '[::]'
    colmena exec --on @hosts --impure -- incus config trust add cluster
  '';
  add-remote-incus = writeShellScriptBin "add-remote-incus" ''
    group=$1
    echo "Add ''${group} group nodes to remote incus"
    jq -c ".hosts | to_entries[] | select(.value.group == \"''${group}\") | .value" config.json | while read -r config
    do
      ipv4_address=$(echo "''${config}" | jq -r '.ipv4_address')
      hostname=$(echo "''${config}" | jq -r '.hostname')
      echo "Add ''${hostname}: ''${ipv4_address}"
      incus remote add "''${hostname}" "''${ipv4_address}" \
        --accept-certificate \
        --token $(ssh -n root@''${ipv4_address} incus config trust add cluster | tail -n+2)
    done
  '';
  copy-img2incus = writeShellScriptBin "copy-img2incus" ''
    ALIAS_CONTAINER="nixos/container"
    ALIAS_VM="nixos/virtual-machine"

    jq -r ".hosts[].name" config.json | while read target
    do
        echo "Copy NixOS images to ''${target}"
        incus image copy --mode=relay ''${ALIAS_CONTAINER} ''${target}: --alias ''${ALIAS_CONTAINER}
        incus image copy --mode=relay ''${ALIAS_VM} ''${target}: --alias ''${ALIAS_VM}
    done
  '';
}
