{ name
, nodeIP
, ...
}:
{
  imports = [
    ./autoresources.nix
    ./ssh.nix
    ./system.nix
  ];

  deployment.targetHost = nodeIP;
  networking.hostName = name;
}