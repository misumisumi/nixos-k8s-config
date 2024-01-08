{ hostname, ... }:
{
  imports = [
    ../init/colmena.nix
  ];
  deployment = {
    tags = [ "hosts" "tertiary" "${hostname}" ];
  };
}
