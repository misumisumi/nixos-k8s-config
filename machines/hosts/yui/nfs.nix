{
  fileSystems = {
    "/export/nfs" = {
      device = "/dev/mapper/..";
      option = ["bind"];
    };
  };
  services.nfs = {
    server = {
      enable = true;
      exports = ''
        /export/nfs         192.168.1.0(rw,fsid=0,no_subtree_check)
      '';
    };
  };
}