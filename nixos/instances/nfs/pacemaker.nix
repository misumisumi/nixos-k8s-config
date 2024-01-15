{ lib
, resourcesByRole
, ...
}:
let
  nfsServers = map
    (r: {
      inherit (r.values) name;
      nodeid = lib.strings.toInt (lib.strings.removePrefix "nfs" r.values.name);
      ring_addrs = [ r.values.ip_address ];
    })
    (resourcesByRole "nfs" "nfs");
in
{
  # For pcs daemon, pcs remote node, DLM, crosync
  networking.firewall.allowedTCPPorts = [ 2224 3121 21064 5404 5405 ];
  services.pacemaker = {
    enable = true;
  };
  services.corosync = {
    enable = true;
    clusterName = "ha-nfs-cluster";
    nodelist = nfsServers;
  };
  users.users.hacluster = {
    initialHashedPassword = "$y$j9T$YLl3n7HYJ5.Gd7JyFmrRI1$FEKOBLvge5sVwV/7t0Nqya4SjoK/r4BIPjxJxUtWWs7";
  };
}