vault_address      = "https://172.16.11.1:8200"
vault_ca_cert_path = "../../../instances/secrets/develop/pki/RootCA/ca.pem"
kv_path            = "secret"
kv_secrets = {
  cloudflare = {
    api_token = "cloudflare.api_token"
    email     = "cloudflare.email"
  }
  piraeus = {
    master_passphrase = "piraeus.master_passphrase"
  }
}
