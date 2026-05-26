{
  user,
  ...
}:
{
  networking.nftables.enable = true;
  users.groups = {
    incus-admin.members = [
      "root"
      "${user}"
    ];
    kvm.members = [
      "root"
      "${user}"
    ];
  };
  virtualisation = {
    incus = {
      enable = true;
      startTimeout = 300;
      preseed = {
        config = {
          "core.https_address" = ":8443";
        };
      };
    };
  };
}
