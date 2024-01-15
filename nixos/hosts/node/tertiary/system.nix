{
  boot = {
    tmp = {
      useTmpfs = true;
      tmpfsSize = "30%";
    };
  };
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };
}
