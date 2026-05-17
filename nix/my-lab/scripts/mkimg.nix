{
  lib,
  writeShellScriptBin,
  incus,
  nixos-rebuild-ng,
  nix,
  rsync,
}:
let
  inherit (lib) getExe;
in
{
  mkimg-lxc = writeShellScriptBin "mkimg.lxc" ''
    flake=$1
    image=''${flake//_//}
    args="''${@:2}"

    img_path="$(${getExe nixos-rebuild-ng} build-image --flake ".#$flake" --image-variant lxc --no-link ''${args[@]})"
    if [ ! -z "$img_path" ]; then
      ${getExe incus} image delete $image
      ${getExe incus} image import "$(${getExe nixos-rebuild-ng} build-image --flake ".#$flake" --image-variant lxc-metadata --no-link)" "$img_path" --alias $image
    fi
  '';
  mkimg-incus-vm = writeShellScriptBin "mkimg.incus-vm" ''
    flake=$1
    image=''${flake//_//}
    args="''${@:2}"

    img_path="$(${getExe nixos-rebuild-ng} build-image --flake ".#$flake" --image-variant incus-vm --no-link ''${args[@]})"
    if [ ! -z "$img_path" ]; then
      ${getExe incus} image delete $image
      ${getExe incus} image import "$(${getExe nixos-rebuild-ng} build-image --flake ".#$flake" --image-variant lxc-metadata --no-link)" "$img_path" --alias $image
    fi
  '';
  mkimg-kexec = writeShellScriptBin "mkimg.kexec" ''
    flake=$1
    args="''${@:2}"
    PROJECT_ROOT="''${FLAKE_ROOT:-$PWD}"
    isProd="$(echo $flake | grep -c "prod")"
    image="$(echo $flake | awk -F_ '{print $3}')"
    output=$PROJECT_ROOT/mnt/develop
    if [ $isProd -eq 1 ]; then
      output=$PROJECT_ROOT/mnt/production
    fi
    output="$output/www/images/kexec/$image"
    build_output=$(${getExe nixos-rebuild-ng} build-image --flake ".#$flake" --image-variant kexec --no-link ''${args[@]})
    if [ ! -z "$build_output" ]; then
      rm -rf "$output"
      mkdir -p "$output"
      cp $build_output $output/nixos-kexec.tar.''${build_output##*.}
    fi
  '';
  mkimg-ipxe = writeShellScriptBin "mkimg.ipxe" ''
    flake=$1
    args="''${@:2}"
    PROJECT_ROOT="''${FLAKE_ROOT:-$PWD}"
    isProd="$(echo $flake | grep -c "prod")"
    image="$(echo $flake | awk -F_ '{print $3}')"
    output=$PROJECT_ROOT/mnt/develop
    if [ $isProd -eq 1 ]; then
      output=$PROJECT_ROOT/mnt/production
    fi
    output="$output/www/images/ipxe/$image"
    build_output=$(${getExe nix} build ".#nixosConfigurations.''${flake}.config.system.build.ipxeImage" --no-link --print-out-paths ''${args[@]})
    if [ ! -z "$build_output" ]; then
      rm -rf "$output"
      mkdir -p "$output"
      ${getExe rsync} -auhz --copy-links --chmod=ug+w --chown=$USER:users "$build_output/" "$output"
    fi
  '';
  mkimg-list = writeShellScriptBin "mkimg.list" ''
    isProd="$(echo $1 | grep -c "prod")"
    PROJECT_ROOT="''${FLAKE_ROOT:-$PWD}"
    output=$PROJECT_ROOT/mnt/develop
    STATIC_FILE=$PROJECT_ROOT/nix/my-lab/roles/static_dev.toml
    if [ $isProd -eq 1 ]; then
      output=$PROJECT_ROOT/mnt/production
      STATIC_FILE=$PROJECT_ROOT/nix/my-lab/roles/static.toml
    fi
    export STATIC_FILE=$STATIC_FILE
    output="$output/www/images/kexec-images.json"
    build_output=$(${getExe nix} build --file ${./mkimg-list.nix} --impure --no-link --print-out-paths ''${args[@]})
    if [ ! -z "$build_output" ]; then
      rm -rf "$output"
      mkdir -p "$(dirname $output)"
      cp $build_output $output
    fi
  '';

  mkimg-dev-wrt = writeShellScriptBin "mkimg.dev-wrt" ''
    flake=$1
    image=''${flake//_//}
    args="''${@:2}"
    img_path="$(${getExe nix} build ".#$flake" --print-out-paths --no-link ''${args[@]})"
    if [ ! -z "$img_path" ]; then
      ${getExe incus} image delete $image
      ${getExe incus} image import "$img_path/$(${getExe nix} eval --raw .#dev_switch_sks8300-8x.passthru.lxc-medadata)" "$img_path/$(${getExe nix} eval --raw .#dev_switch_sks8300-8x.passthru.qcow2)" --alias $image
    fi
  '';
}
