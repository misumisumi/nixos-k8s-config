{
  secretPath,
  ...
}:
{
  system.build.extraContents = [
    {
      source = secretPath + "/pki/vault/server-chain.pem";
      target = "/etc/vault/tls/server.pem";
      user = "vault";
      group = "vault";
      mode = "0640";
    }
    {
      source = secretPath + "/pki/vault/server-key.pem";
      target = "/etc/vault/tls/server-key.pem";
      user = "vault";
      group = "vault";
      mode = "0400";
    }
  ];
}
