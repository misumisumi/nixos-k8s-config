{ inputs, stateVersion }:
{
  meta = {
    allowApplyAll = false; # Due to mixed configuration of physical nodes and virtual machines
    nixpkgs =
      let
        nixpkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config = { allowUnfree = true; };
        };
      in
      import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [
          inputs.flakes.overlays.default
          (import ../../patches { inherit nixpkgs-unstable; })
        ];
      };
    specialArgs = {
      inherit inputs;
      inherit stateVersion;
    };
  };
}
