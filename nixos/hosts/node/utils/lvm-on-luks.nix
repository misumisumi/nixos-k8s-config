{
  deviceProperties = device: idx: keyFile: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "CryptedDisk${idx}";
            extraOpenArgs = [ ];
            settings = {
              inherit keyFile;
              allowDiscards = true;
            };
            # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
            initrdUnlock = false;
            content = {
              type = "lvm_pv";
              vg = "PoolDisk${idx}";
            };
          };
        };
      };
    };
  };
}
