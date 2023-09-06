{ lib
, pkgs
, user
, ...
}: {
  environment.pathsToLink = [ "/share/zsh" ];
  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };
  users.users.root.initialHashedPassword = lib.mkDefault "$y$j9T$vwHggX/iAmiJIqh4UeGjh0$u/eFvPAIamTvSFeAacsGL8UwPa5izO7tOiJlNcwQhy1";
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    initialHashedPassword = "$6$viPBN7o74kK3JdGw$4zKIuVEbgqvTqLIae/G5rOgrYXWSccB5MQp9/0HgeitQIocLg2.GeG7TWYYfNhZdgs4FNHJuPg5SqSrrIkpr51";
    extraGroups = [ "wheel" "uucp" "kvm" "input" "lxd" ];
    useDefaultShell = true;
    subUidRanges = [
      # Using rootless container
      {
        count = 100000;
        startUid = 300000;
      }
    ];
    subGidRanges = [
      {
        count = 100000;
        startGid = 300000;
      }
    ];
  };

  security.sudo.wheelNeedsPassword = true; # User does need to give password when using sudo.
}
