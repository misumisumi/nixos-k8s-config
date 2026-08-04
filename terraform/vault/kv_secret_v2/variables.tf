variable "vault_address" {
  type        = string
  description = "Vault server address (VIP)"
}

variable "vault_ca_cert_path" {
  type        = string
  description = "Path to Vault CA certificate file for TLS verification"
  default     = ""
}

variable "kv_path" {
  type        = string
  description = "KV v2 secrets engine mount path"
  default     = "secret"
}

variable "kv_secrets" {
  type        = map(map(string))
  description = <<-EOT
    Map of Vault KV secret names to their data field mappings.
    Each entry: secret_name = { output_key = "sops_yaml_path" }
    The sops_yaml_path uses dot notation for nested keys in the decrypted SOPS YAML.
    Example:
    cloudflare = {
      api_token = "cloudflare.api_token"
      email     = "cloudflare.email"
    }
    piraeus = {
      master_passphrase = "piraeus.master_passphrase"
    }
  EOT
  default     = {}
}
