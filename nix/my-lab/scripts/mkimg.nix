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
    output="$output/www/kexec/images/$image"
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
    output="$output/www/ipxe/images/$image"
    build_output=$(${getExe nix} build ".#nixosConfigurations.''${flake}.config.system.build.ipxeImage" --no-link --print-out-paths ''${args[@]})
    if [ ! -z "$build_output" ]; then
      rm -rf "$output"
      ${getExe rsync} -auhz --copy-links --chmod=ug+w --chown=$USER:users "$build_output/" "$output"
    fi
  '';
}
