{
  config,
  static,
  group,
  hostname,
  ...
}:
let
  acme = static.${group}.${hostname}.acme;
in
{
  # Cloudflare DNS-01 用の資格情報(実体は sops で暗号化)
  sops.secrets."acme-env" = { };

  security.acme = {
    acceptTerms = true;
    defaults.email = acme.email;
    certs.${acme.certName} = {
      domain = acme.certName;
      extraDomainNames = [ "*.${acme.certName}" ];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."acme-env".path;
      group = "nginx";
    };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    defaultListen = [
      {
        addr = "";
      }
    ];
  };
}
