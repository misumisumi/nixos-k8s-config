{ name
, ...
}:
{
  imports = [
    ./modules.nix
  ];
  networking.hostName = name;
}
