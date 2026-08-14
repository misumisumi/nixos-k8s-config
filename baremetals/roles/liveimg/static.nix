{
  liveimg = {
    first-image = {
      system = "x86_64-linux";
      user = "nixos";
      hostname = "first-image";
    };
    second-image = {
      system = "x86_64-linux";
      user = "nixos";
      hostname = "second-image";
      networks = {
        manage = {
          subnet = "192.168.2.0/24";
        };
      };
    };
    nixos-livecd = {
      system = "x86_64-linux";
      user = "nixos";
      hostname = "nixos-livecd";
    };
    nixos-netboot = {
      system = "x86_64-linux";
      user = "nixos";
      hostname = "nixos-netboot";
    };
  };
}
