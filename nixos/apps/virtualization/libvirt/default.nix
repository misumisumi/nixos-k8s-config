{ pkgs
, user
, ...
}: {
  environment = {
    systemPackages = with pkgs; [
      win-virtio
      dmidecode # Show BIOS info
    ];
  };
  users = {
    groups = {
      libvirt = {
        members = [ "root" "${user}" ];
      };
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true; # Virtual drivers
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        ovmf = {
          enable = true;
          packages = with pkgs; [ OVMFFull.fd ];
        };
        swtpm.enable = true;
        # verbatimConfig = ''
        #   nvram = [
        #     "${pkgs.OVMFFull}/FV/OVMF.fd:${pkgs.OVMFFull}/FV/OVMF_VARS.fd",
        #     "${pkgs.OVMFFull}/FV/OVMF.secboot.fd:${pkgs.OVMFFull}/FV/OVMF_VARS.fd",
        #   ]
        # '';
      };
    };
    spiceUSBRedirection.enable = true; # USB passthrough
  };
}
