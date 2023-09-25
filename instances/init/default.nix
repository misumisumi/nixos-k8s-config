{ name
, nodeIP
, ...
}:
{
  imports = [
    ./ssh.nix
    ./system.nix
  ];

  deployment.targetHost = nodeIP;
  networking.hostName = name;
}