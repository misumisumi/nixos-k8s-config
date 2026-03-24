# {
#   self,
#   inputs,
#   lib,
# }:
# {
#   "mngr_image-server" = lib.nixosSystem {
#     system = "x86_64-linux";
#     specialArgs = {
#       user = "nixos";
#       hostname = "image-server";
#       type = "instance";
#       inherit
#         self
#         inputs
#         ;
#     }; # specialArgs give some args to modules
#     modules = [
#       ./
#       ./_init/incus/container
#     ];
#   };
# }
# // (
#   let
#     inherit (builtins) listToAttrs;
#     inherit (lib)
#       nameValuePair
#       range
#       nixosSystem
#       optionalAttrs
#       ;
#     switch =
#       {
#         role,
#         id ? null,
#       }:
#       nixosSystem {
#         system = "x86_64-linux";
#         specialArgs = {
#           user = "nixos";
#           type = "instance";
#           inherit
#             self
#             inputs
#             ;
#         }
#         // optionalAttrs (id == null) {
#           hostname = role;
#         }
#         // optionalAttrs (id != null) {
#           hostname = "${role}${id}";
#           switch_id = id;
#         }; # specialArgs give some args to modules
#         modules = [
#           ./bgp-test/${role}
#           ./_init/incus/virtual-machine
#           ./_init/nix
#           inputs.nixos-linstor.nixosModules.default
#         ];
#       };
#     ix2215 = [
#       (nameValuePair "bgp.ix2215" (switch {
#         role = "ix2215";
#       }))
#     ];
#     ibl2 = [
#       (nameValuePair "bgp.ibl2" (switch {
#         role = "ibl2";
#       }))
#     ];
#     border-leaf = [
#       (nameValuePair "bgp.border-leaf" (switch {
#         role = "border-leaf";
#       }))
#     ];
#     spines = map (
#       x:
#       let
#         # x' = lib.trace (toString x) (toString x);
#         x' = toString x;
#       in
#       nameValuePair "bgp.spine${x'}" (switch {
#         role = "spine";
#         id = x';
#       })
#     ) (range 2 2);
#     leafs = map (
#       x:
#       let
#         x' = toString x;
#       in
#       nameValuePair "bgp.leaf${x'}" (switch {
#         role = "leaf";
#         id = x';
#       })
#     ) (range 4 6);
#     testNodes = ix2215 ++ ibl2 ++ spines ++ leafs ++ border-leaf;
#   in
#   listToAttrs testNodes
# )
{
  self,
  inputs,
  lib,
}:
let
  inherit (builtins) head;
  inherit (lib)
    nameValuePair
    mapAttrs'
    mapAttrsToList
    importTOML
    optional
    ;
  systemSetting =
    {
      group,
      tag,
      system,
      hostname,
      user,
      isTest ? false,
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          self
          inputs
          hostname
          group
          user
          isTest
          ;
      }; # specialArgs give some args to modules
      modules = [
        inputs.sops-nix.nixosModules.sops
        self.nixosModules.default
        ./share/modules/static.nix
        ./${group}/${tag}/common
      ]
      ++ optional isTest ./${group}/${tag}/test
      ++ optional (!isTest) ./${group}/${tag}/production;
    };
  group_and_hosts = importTOML ./static.toml;
in
(head (
  mapAttrsToList (
    group: hosts:
    (mapAttrs' (
      tag: value:
      nameValuePair "${group}_${tag}" (systemSetting {
        inherit group tag;
        inherit (value) system hostname user;
      })
    ) hosts)
  ) group_and_hosts
))
// (head (
  mapAttrsToList (
    group: hosts:
    (mapAttrs' (
      tag: value:
      nameValuePair "test_${group}_${tag}" (systemSetting {
        inherit group tag;
        inherit (value) system hostname user;
        isTest = true;
      })
    ) hosts)
  ) group_and_hosts
))
