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
  source_file = "${path.module}/branch/${terraform.workspace}.yaml"
}

locals {
  decrypted = yamldecode(data.sops_file.secrets.raw)
}

provider "vault" {
  address      = var.vault_address
  ca_cert_file = var.vault_ca_cert_path
  token        = local.decrypted["vault_root_token"]
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.kubernetes_auth_path
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend              = vault_auth_backend.kubernetes.path
  kubernetes_host      = var.kubernetes_host
  kubernetes_ca_cert   = file(var.kubernetes_ca_cert_path)
  disable_local_ca_jwt = true
  issuer               = var.kubernetes_issuer
  # token_reviewer_jwt   = local.decrypted["token_reviewer_jwt"]
  token_reviewer_jwt = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4cVBXcDBRQjA4MU5JMEZ0Q3BRUkZqRzFhSnBBeV8xWXYtZm44TUJYd00ifQ.eyJhdWQiOlsiYXBpIiwiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjIl0sImV4cCI6NDkzOTU4ODg1MSwiaWF0IjoxNzg1OTg4ODUxLCJpc3MiOiJodHRwczovL2t1YmVybmV0ZXMuZGVmYXVsdC5zdmMiLCJqdGkiOiIyZDU0MmZiZC1iNzdhLTQ0ZTYtOGVkZC0yMmE1MDNiNWFkZjIiLCJrdWJlcm5ldGVzLmlvIjp7Im5hbWVzcGFjZSI6Imt1YmUtc3lzdGVtIiwic2VydmljZWFjY291bnQiOnsibmFtZSI6InZhdWx0LXRva2VuLXJldmlld2VyIiwidWlkIjoiMjk1OTU4ZmYtYzJiMi00Yzk4LTlkNzYtNTcwOWU2Y2I2MDNlIn19LCJuYmYiOjE3ODU5ODg4NTEsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTp2YXVsdC10b2tlbi1yZXZpZXdlciJ9.aD7sxsD-KQNX87-mISiltYPA-xntNyxUVO4-dhGQKpsLcGjeByKmuJkZ_P0zTRaC4UNQgrV5S1E_FIUwy5qhpR5vDd6K08E2CirILJIyvWZoOpoO9qHultkCU2lIa0ags3TEEmDOQUXpKEQsHbw21xCGRiHtm_AjpnUJQjquY0msXVo1Efxn5jyl969vFOT8CqQk33UKHhob6JbiC9BUXf7HP8bDNDXnHsGwTI-swFvLf1DiaYcww-4952m6r6Z2AvBtMk1KChbH9A298jBB3yanMW9b7W4crP3nHmAbOeiVZLkXGLwUEktIEeL0B5AiILZurXKI5i1d9PrSRZFrKw"
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
