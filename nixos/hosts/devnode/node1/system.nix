{
  boot = {
    tmp = {
      useTmpfs = true;
      tmpfsSize = "40%";
    };
  };
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
  };
}
