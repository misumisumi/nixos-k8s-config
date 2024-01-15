{ hostname, ... }:
{
  imports = [
    ../init/colmena.nix
  ];
  deployment = {
    tags = [ "hosts" "primary" "${hostname}" ];
  };
}
