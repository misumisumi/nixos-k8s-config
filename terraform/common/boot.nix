{
  boot = {
    growPartition = true;
    kernelParams = ["console=ttyS0"];
    loader.grub.device = "/dev/vda";
    loader.timeout = 1;
  };
}