{pkgs, ...}: {
  hardware = {
    nvidia.powerManagement.enable = true;
    opengl.extraPackages = with pkgs; [
      # intel-media-driver
      # intel-ocl
      # vaapiIntel
      libvdpau-va-gl
      vaapiVdpau
    ];
  };
}