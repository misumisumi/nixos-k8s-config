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
  source_file = "${path.module}/sops/${terraform.workspace}.yaml"
}

provider "vault" {
  address      = var.vault_address
  ca_cert_file = var.vault_ca_cert_path
  token        = data.sops_file.secrets.data["vault_root_token"]
}

resource "terraform_data" "workspace" {
  input = terraform.workspace
}

resource "vault_mount" "kv_v2" {
  path        = var.kv_path
  type        = "kv-v2"
  description = "KV v2 secrets engine"
}

locals {
  kv_secrets = {
    for name, mapping in var.kv_secrets : name => {
      for output_key, sops_key in mapping : output_key => try(data.sops_file.secrets.data[sops_key], "")
    }
  }
}

resource "vault_kv_secret_v2" "this" {
  for_each = {
    for name, mapping in local.kv_secrets : name => mapping
    if length(mapping) > 0
  }

  mount               = vault_mount.kv_v2.path
  name                = each.key
  delete_all_versions = true
  data_json           = jsonencode(each.value)
}
