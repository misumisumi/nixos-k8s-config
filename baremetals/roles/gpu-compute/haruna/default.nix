{
  hostname,
  inputs,
  self,
  system,
  user,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.homelab-modules.nixosModules.dgx-spark
    ./cockpit.nix
    ./container.nix
    ./network.nix
    ./pkgs.nix
    ({ pkgs, ... }: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm.bak";
        extraSpecialArgs = {
          inherit
            self
            inputs
            hostname
            user
            system
            ;
        };
        sharedModules = [
          inputs.flakes.homeManagerModules.default
          inputs.sops-nix.homeManagerModules.sops
        ];
        users."${user}" = {
          imports = [ ./home ];
          home.stateVersion = pkgs.lib.trivial.release;
        };
      };
    })
  ];

  nixpkgs.hostPlatform = system;
  apt = {
    enable = true;
    onActivation.autoUpdate = true;
  };
  nix = {
    enable = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "${user}"
      ];
    };
  };
  environment.etc."hostname".text = hostname;
  services.userborn.enable = true;

  users = {
    groups = {
      ${user} = { };
      "docker" = { };
    };
    users.${user} = {
      isNormalUser = true;
      group = "${user}";
      extraGroups = [
        "adm"
        "audio"
        "dip"
        "docker"
        "lpadmin"
        "plugdev"
        "sudo"
        "users"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCGcY4v0aRzAO+hLnGhEaU7JArt/Wrn8FuIgFcovlad sumi@mother-2021-03-12"
      ];
    };
  };
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    hostKeys = [
      {
        type = "rsa";
        bits = 4096;
        path = "/etc/ssh/ssh_host_rsa_key";
        openSSHFormat = true;
      }
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
        comment = "dgx-spark-2026-09-02";
      }
    ];
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = false;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };
}
