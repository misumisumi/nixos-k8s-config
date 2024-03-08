{ lib, ... }:
let
  hosts-config = (import ../../utils/hosts.nix { }).hosts;
in
lib.mapAttrs
  (tag: config: {
    "${tag}-addtionalfs" = import ./node/${tag}/additionalfs.nix { inherit lib; };
  })
  hosts-config
