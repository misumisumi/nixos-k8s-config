terraform {
  required_version = "~> 1.10.0"
  required_providers {
    vault = {
      source  = "registry.opentofu.org/hashicorp/vault"
      version = "~> 4.0.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.3.0"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "${path.module}/secrets/${terraform.workspace}.yaml"
}

provider "vault" {
  address      = var.vault_address
  ca_cert_file = var.vault_ca_cert_path
  token        = data.sops_file.secrets.data["vault_root_token"]
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.kubernetes_auth_path
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend              = vault_auth_backend.kubernetes.path
  kubernetes_host      = var.kubernetes_host
  kubernetes_ca_cert   = file(var.kubernetes_ca_cert_path)
  disable_local_ca_jwt = false
}

resource "vault_policy" "eso" {
  name   = "external-secrets"
  policy = <<-EOT
path "secret/data/*" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "eso" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "external-secrets"
  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = ["external-secrets"]
  token_policies                   = [vault_policy.eso.name]
  token_ttl                        = 3600
}
