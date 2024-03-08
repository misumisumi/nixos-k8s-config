{ hostname, ... }:
{
  imports = [
    ../init/colmena.nix
  ];
  deployment = {
    tags = [ "devnode" "${hostname}" ];
  };
}
