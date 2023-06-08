{
  inputs,
  lib,
  name,
  resourcesByRole,
  ...
}: let
  tar = resourcesByRole (builtins.head (builtins.split "[0-9]|-" name));
  targetNodes = builtins.listToAttrs (map (r: {"${r.values.name}" = "${r.values.type}";}) (lib.traceSeq tar tar));
  machineType = builtins.head (lib.filterAttrs (n: r: n == name) (lib.traceSeq targetNodes targetNodes));
in
  if (machineType == "virtual-machine")
  then inputs.lxd-nixos.nixosModules.virtual-machine
  else inputs.lxd-nixos.nixosModules.container