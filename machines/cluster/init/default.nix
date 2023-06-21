{
  name,
  self,
  ...
}: let
  inherit (import ../../../utils/utils.nix) nodeIP;
in {
  imports = [
    ./autoresources.nix
    ./ssh.nix
    ./system.nix
  ];

  deployment.targetHost = nodeIP self;
  networking.hostName = name;
}