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
# pythonPackages patch template
# (final: prev: {
#   python3Packages = prev.python3Packages.override {
#     overrides = pfinal: pprev: {
#       package = pprev.package.overridePythonAttrs (old: {
#       });
#     };
#   };
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
# Patch from https://github.com/NixOS/nixpkgs/pull/211600
{ nixpkgs-unstable, ... }:
final: prev: {
  inherit (nixpkgs-unstable) doq udev-gothic-nf;
  setup-netboot-compornents = prev.callPackage ./setup-netboot-compornents.nix { };
  terraform-providers = prev.terraform-providers // {
    inherit (nixpkgs-unstable.terraform-providers) incus;
  };
}
