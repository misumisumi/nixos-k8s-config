{
  inputs,
  stateVersion,
}:
{
  meta = {
    allowApplyAll = false; # Due to mixed configuration of physical nodes and virtual machines
    nixpkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [inputs.flakes.overlays.default];
    };
    specialArgs = {
      inherit inputs;
      inherit stateVersion;
    };
  };
}
// (import ./cluster {inherit inputs;})
// (import ./hosts {inherit inputs;})