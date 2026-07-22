vault_address      = "https://172.16.11.1:8200"
vault_ca_cert_path = "../../../nix/k8s/secrets/develop/pki/RootCA/ca.pem"
kv_path            = "secret"
kv_secrets = {
  cloudflare = {
    api_token = "cloudflare_api_token"
    email     = "cloudflare_email"
  }
}
