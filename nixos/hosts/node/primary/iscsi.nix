{
  services.tgtd = {
    enable = true;
    nop_interval = 30;
    nop_count = 10;
    targets = {
      "iqn.2023-09.com.remotefs:target00" = {
        backingStores = [ ];
        initiatorAddresses = [ ];
      };
      "iqn.2023-09.com.remotefs:target01" = {
        backingStores = [ ];
        initiatorAddresses = [ ];
      };
      "iqn.2023-09.com.remotefs:target02" = {
        backingStores = [ ];
        initiatorAddresses = [ ];
      };
    };
  };
}
