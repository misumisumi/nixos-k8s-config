{ pkgs, ... }:
{
  users.groups.podman = { };
  apt.packages = [
    #   "podman"
    #   "podman-compose"
    #   # for rootless containers
    #   "aardvark-dns"
    #   "catatonit"
    #   "slirp4netns"
    "uidmap"
  ];
  environment = {
    systemPackages = with pkgs; [
      podman
      podman-compose
    ];
    etc."containers/registries.conf.d/system-manager.conf".text = ''
      unqualified-search-registries = ["docker.io"]
      short-name-mode = "enforcing"
    '';
  };
  systemd = {
    packages = with pkgs; [
      podman
    ];
    sockets.podman = {
      wantedBy = [ "sockets.target" ];
      socketConfig.SocketGroup = "podman";
    };
    user.sockets.podman.wantedBy = [ "sockets.target" ];
  };
}
