{
  lib,
  user,
  pkgs,
  config,
  secretsPath,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  environment.pathsToLink = [ "/share/bash-completion" ];
  programs.bash = {
    completion.enable = true;
    enableLsColors = true;
    vteIntegration = true;
  };

  users.users."${user}" = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [
      "wheel"
    ];
    initialHashedPassword = mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";
  };
  users.users.root.initialHashedPassword = mkForce "$y$j9T$2i4ZUQSB0zKtYfaf9YLuZ0$rwxfC/yKFR.zejBm.X00K/JZJSoYVOnnLkSLQ50N5T7";

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      PasswordAuthentication = false;
      ChallengeResponseAuthentication = false;
      PubkeyAuthentication = true;
    };
  };
  programs.ssh.extraConfig = ''
    Host *
      UserKnownHostsFile /dev/null
      StrictHostKeyChecking no
      # there's nobody around that can input password
      PreferredAuthentications publickey
  '';
  systemd.tmpfiles.rules = [
    "d /home/${user}/.ssh 0700 ${user} ${user} -"
    "f /home/${user}/.ssh/id_ed25519 0600 ${user} ${user} -"
    "f /home/${user}/.ssh/id_ed25519.pub 0644 ${user} ${user} -"
    "f /etc/ssh/ssh_host_ed25519 0600 root root -"
    "f /etc/ssh/ssh_host_ed25519_key.pub 0644 root root -"
  ];
  system.build.tarball = lib.mkForce (
    pkgs.callPackage "${pkgs.path}/nixos/lib/make-system-tarball.nix" {
      fileName = config.image.baseName;
      extraArgs = "--owner=0";

      storeContents = [
        {
          object = config.system.build.toplevel;
          symlink = "none";
        }
      ];

      contents = [
        {
          source = config.system.build.toplevel + "/init";
          target = "/sbin/init";
        }
        # Technically this is not required for lxc, but having also make this configuration work with systemd-nspawn.
        # Nixos will setup the same symlink after start.
        {
          source = config.system.build.toplevel + "/etc/os-release";
          target = "/etc/os-release";
        }
        {
          source = "${secretsPath}/instances/tiny-router/ssh/id_ed25519";
          target = "/home/${user}/.ssh/id_ed25519";
        }
        {
          source = "${secretsPath}/instances/tiny-router/ssh/id_ed25519.pub";
          target = "/home/${user}/.ssh/id_ed25519.pub";
        }
        {
          source = "${secretsPath}/instances/tiny-router/ssh/ssh_host_ed25519_key";
          target = "/etc/ssh/ssh_host_ed25519";
        }
        {
          source = "${secretsPath}/instances/tiny-router/ssh/ssh_host_ed25519_key.pub";
          target = "/etc/ssh/ssh_host_ed25519_key.pub";
        }
      ];

      extraCommands = "mkdir -p proc sys dev";
    }
  );
  # fileSystems =
  #   let
  #     inherit (lib) mkImageMediaOverride;
  #   in
  #   {
  #     "/home/${user}/.ro-ssh" = mkImageMediaOverride {
  #       fsType = "squashfs";
  #       device = "../user-ssh.squashfs";
  #       options = [
  #         "loop"
  #       ]
  #       ++ lib.optional (config.boot.kernelPackages.kernel.kernelAtLeast "6.2") "threads=multi";
  #       neededForBoot = true;
  #     };
  #     "/home/${user}/.rw-ssh" = {
  #       fsType = "tmpfs";
  #       options = [ "mode=0700" ];
  #       neededForBoot = true;
  #     };
  #     "/home/${user}/.ssh" = {
  #       overlay = {
  #         lowerdir = [ "/home/${user}/.ro-ssh" ];
  #         upperdir = [ "/home/${user}/.rw-ssh/ssh" ];
  #         workdir = [ "/home/${user}/.rw-ssh/work" ];
  #       };
  #       neededForBoot = true;
  #     };
  #     "/etc/.ro-ssh" = mkImageMediaOverride {
  #       fsType = "squashfs";
  #       device = "../etc-ssh.squashfs";
  #       options = [
  #         "loop"
  #       ]
  #       ++ lib.optional (config.boot.kernelPackages.kernel.kernelAtLeast "6.2") "threads=multi";
  #       neededForBoot = true;
  #     };
  #     "/etc/.rw-ssh" = {
  #       fsType = "tmpfs";
  #       options = [ "mode=0700" ];
  #       neededForBoot = true;
  #     };
  #     "/etc/ssh" = {
  #       overlay = {
  #         lowerdir = [ "/etc/.ro-ssh" ];
  #         upperdir = [ "/etc/.rw-ssh/ssh" ];
  #         workdir = [ "/etc/.rw-ssh/work" ];
  #       };
  #       neededForBoot = true;
  #     };
  #   };
  # system.build.squashfsSystemSSHKey = pkgs.stdenv.mkDerivation rec {
  #   name = "system-ssh-key-squashfs";
  #   nativeBuildInputs = [ pkgs.squashfsTools ];
  #   buildCommand = ''
  #     mkdir -p ssh
  #     cat << EOF > ssh/ssh_host_ed25519_key
  #     ${readFile ../.secrets/tiny-router/ssh/ssh_host_ed25519_key}
  #     >>EOF
  #     cat << EOF > ssh/ssh_host_ed25519_key.pub
  #     ${readFile ../.secrets/tiny-router/ssh/ssh_host_ed25519_key.pub}
  #     >>EOF

  #     mkdir -p $out
  #     mksquashfs ssh $out/${name}.squashfs -comp ${config.netboot.squashfsCompression} -b 1M -keep-as-directory -all-root
  #   '';
  # };
  # system.build.squashfsUserSSHKey = pkgs.stdenv.mkDerivation rec {
  #   name = "user-ssh-key-squashfs";
  #   nativeBuildInputs = [ pkgs.squashfsTools ];
  #   buildCommand = ''
  #     mkdir -p ssh
  #     cat << EOF > ssh/id_ed25519
  #     ${readFile ../.secrets/tiny-router/ssh/id_ed25519}
  #     >>EOF
  #     cat << EOF > ssh/id_ed25519.pub
  #     ${readFile ../.secrets/tiny-router/ssh/id_ed25519.pub}
  #     >>EOF

  #     mkdir -p $out
  #     mksquashfs ssh $out/${name}.squashfs -comp ${config.netboot.squashfsCompression} -b 1M -keep-as-directory -all-root
  #   '';
  # };
  # system.build.netbootRamdisk = pkgs.makeInitrdNG {
  #   inherit (config.boot.initrd) compressor compressorArgs;
  #   prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

  #   contents = [
  #     {
  #       source = config.system.build.squashfsStore;
  #       target = "/nix-store.squashfs";
  #     }
  #     {
  #       source = config.system.build.squashfsSystemSSHKey;
  #       target = "/etc-ssh.squashfs";
  #     }
  #     {
  #       source = config.system.build.squashfsUserSSHKey;
  #       target = "/user-ssh.squashfs";
  #     }
  #   ];
  # };
}
