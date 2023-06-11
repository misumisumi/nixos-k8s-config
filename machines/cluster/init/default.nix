{
  name,
  self,
  stateVersion,
  ...
}: let
  inherit (import ../../../utils/utils.nix) nodeIP;
in {
  imports = [
    ./autoresources.nix
    ./ssh.nix
  ];

  deployment.targetHost = nodeIP self;
  networking.hostName = name;

  time.timeZone = "Asia/Tokyo"; # Time zone and internationalisation

  system = {
    inherit stateVersion;
    # NixOS settings
    autoUpgrade = {
      # Allow auto update
      enable = false;
    };
  };
}