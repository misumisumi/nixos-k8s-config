{ hostname, ... }:
{
  imports = [
    ../init/colmena.nix
  ];
  deployment = {
    tags = [ "hosts" "secondary" "${hostname}" ];
  };
}
