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
    Each entry: secret_name = { output_key = "sops_file_key" }
    Example:
    cloudflare = {
      api_token = "cloudflare_api_token"
      email     = "cloudflare_email"
    }
  EOT
  default     = {}
}
