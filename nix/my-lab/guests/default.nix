{
  self,
  inputs,
  lib,
}:
{
  tiny-router = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      user = "nixos";
      hostname = "tiny-router";
      type = "instance";
      inherit
        self
        inputs
        ;
    }; # specialArgs give some args to modules
    modules = [
      ./tiny-router
      ./_init/incus/container
    ];
  };
}
// (
  let
    inherit (builtins) listToAttrs;
    inherit (lib)
      nameValuePair
      range
      nixosSystem
      optionalAttrs
      ;
    switch =
      {
        role,
        id ? null,
      }:
      nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          user = "nixos";
          type = "instance";
          inherit
            self
            inputs
            ;
        }
        // optionalAttrs (id == null) {
          hostname = role;
        }
        // optionalAttrs (id != null) {
          hostname = "${role}${id}";
          switch_id = id;
        }; # specialArgs give some args to modules
        modules = [
          ./bgp-test/${role}
          ./_init/incus/virtual-machine
          ./_init/nix
        ];
      };
    ix2215 = [
      (nameValuePair "bgp.ix2215" (switch {
        role = "ix2215";
      }))
    ];
    ibl2 = [
      (nameValuePair "bgp.ibl2" (switch {
        role = "ibl2";
      }))
    ];
    spines = map (
      x:
      let
        # x' = lib.trace (toString x) (toString x);
        x' = toString x;
      in
      nameValuePair "bgp.spine${x'}" (switch {
        role = "spine";
        id = x';
      })
    ) (range 3 3);
    leafs = map (
      x:
      let
        x' = toString x;
      in
      nameValuePair "bgp.leaf${x'}" (switch {
        role = "leaf";
        id = x';
      })
    ) (range 4 7);
    testNodes = ix2215 ++ ibl2 ++ spines ++ leafs;
  in
  listToAttrs testNodes
)
