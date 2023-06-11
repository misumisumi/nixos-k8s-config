{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
  ];

  nix = {
    settings = {
      cores = 2;
      max-jobs = 2;
    };
    extraOptions = ''
      binary-caches-parallel-connections = 4
    '';
  };
}