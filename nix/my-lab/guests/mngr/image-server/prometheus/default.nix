{
  services.prometheux = {
    enable = true;
    scrapeConfigs = {
      "file_based_dynamic_clients" = {
        file_sd_configs = [
          {
            files = "/etc/prometheus/*.json";
          }
        ];
      };
    };
  };
}
