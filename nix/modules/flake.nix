{
  outputs = _: {
    nixosModules = import ./default.nix;
  };
}
