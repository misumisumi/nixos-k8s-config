# override: default.nixに記載の属性をオーバライドする
# overrideAttrs: default.nixに記載されていない属性も追加できる
# Package patch template
# (final: prev: {
#   package = prev.package.overrideAttrs (old: {
#   });
# })
# Unwrapped package patch template
# (final: prev: {
#   package = prev.package.unwrapped.override (old: {
#   });
# })
# 特殊なやつはcallPackageを呼ぶと良い
#  package = prev.callPackage "${prev.path}/path/to/package" {
#    buildGoModule = args: prev.buildGoModule (args // rec {
#    });
#  };
# pythonPackages patch template
# (final: prev: {
#   python3 =
#     let
#       pythonPackagesOverlays = (prev.pythonPackagesOverlays or [ ]) ++ [
#         (pfinal: pprev: {
#           package = pprev.package.overridePythonAttrs (old: {
#           });
#         })
#       ];
#       self = prev.python3.override {
#         inherit self;
#         packageOverrides = prev.lib.composeManyExtensions pythonPackagesOverlays;
#       };
#     in
#     self;
# })
# haskellPackages patch template
# (final: prev: {
#   haskellPackages = prev.haskellPackages.override {
#     overrides = hself: hsuper: {
#       # Can add/override packages here
#       package = prev.haskell.lib.doJailbreak hsuper.package;
#     };
#   };
# })
# (final: prev: {
#   embree = pkgs-stable.embree;
#   openimagedenoise = pkgs-stable.openimagedenoise;
#   blender = pkgs-stable.blender;
#   spotify = pkgs-stable.spotify;
# })
{ nixpkgs-unstable, ... }:
final: prev: {
  inherit (nixpkgs-unstable)
    cockpit
    cockpit-files
    cockpit-machines
    ;

  rbash = prev.runCommandNoCC "rbash-${prev.bashInteractive.version}" { } ''
    mkdir -p $out/bin
    ln -s ${prev.bashInteractive}/bin/bash $out/bin/rbash
  '';
  mkpasswd-pihole = prev.writeShellScriptBin "mkpasswd.pihole" ''
    PASSWD=$1
    [ -z "$PASSWD" ] && { echo "Usage: mkpasswd.pihole <password>"; exit 1; }
    printf '%s' "$PASSWD" | sha256sum | cut -d' ' -f1 | tr -d '\n' | sha256sum | cut -d' ' -f1
  '';
  inherit (prev.callPackage ../scripts/mkimg.nix { })
    mkimg-lxc
    mkimg-kexec
    mkimg-ipxe
    mkimg-incus-vm
    mkimg-list
    mkimg-oci
    mkimg-dev-wrt
    ;
}
