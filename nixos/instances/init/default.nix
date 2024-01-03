{ name
, nodeIP
, ...
}:
{
  imports = [
    ./modules.nix
    ./hive.nix
  ];
  networking.hostName = name;
}
