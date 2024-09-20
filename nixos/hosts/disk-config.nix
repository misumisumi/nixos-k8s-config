{ lib, ... }:
let
  hosts-config = (import ../../utils/hosts.nix { }).hosts;
in
lib.mapAttrs (tag: config: import ./${config.group}/${tag}/additionalfs.nix { inherit lib; }) hosts-config
