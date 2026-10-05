# Cloudflare の DNS / Tunnel / Access をエントリ単位で管理する。
#
# entries の各要素は address の有無で挙動が変わる:
#   - address あり: DNS レコード(A/AAAA)のみ作成
#   - address なし: Cloudflare Tunnel を作成(locally-managed) + CNAME で公開
#                   (access = true なら Cloudflare Access で保護)
#
# 前提（branch/<workspace>.yaml に sops で格納）:
#   cloudflare:
#     api_token:  <Cloudflare API Token>
#     account_id: <Account ID>
#     zone_id:    <Zone ID (misumi-sumi.com)>
#   cloudflared:
#     account_tag: <Account ID>          # credentials の AccountTag
#     tunnels:
#       <entry-key>:
#         secret: <openssl rand -base64 32>
terraform {
  required_version = "~> 1.10.0"
  required_providers {
    cloudflare = {
      source  = "registry.opentofu.org/cloudflare/cloudflare"
      version = "~> 5.0"
    }
    sops = {
      source  = "registry.opentofu.org/carlpett/sops"
      version = "~> 1.3.0"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "${path.module}/branch/${terraform.workspace}.yaml"
}

locals {
  secrets    = yamldecode(data.sops_file.secrets.raw)
  account_id = local.secrets.cloudflare.account_id
  zone_id    = local.secrets.cloudflare.zone_id

  tunnel_entries  = { for k, e in var.entries : k => e if e.address == null }
  address_entries = { for k, e in var.entries : k => e if e.address != null }
  fqdn            = { for k, e in var.entries : k => "${e.name}.${var.zone}" }
}

provider "cloudflare" {
  api_token = local.secrets.cloudflare.api_token
}

# --- Tunnel (locally-managed) ---
# credentials JSON は sops の tunnel secret から Nix 側 (oci/cloudflared.nix) で組み立てる。
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  for_each = local.tunnel_entries

  account_id    = local.account_id
  name          = each.value.name
  config_src    = "local"
  tunnel_secret = local.secrets.cloudflared.tunnels[each.key].secret
}

resource "cloudflare_dns_record" "tunnel" {
  for_each = local.tunnel_entries

  zone_id = local.zone_id
  name    = each.value.name
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel[each.key].id}.cfargotunnel.com"
  # Tunnel は Cloudflare のプロキシ経由でルーティングされるため proxied 必須
  proxied = true
  ttl     = 1
}

# --- address のみのレコード (A / AAAA) ---
resource "cloudflare_dns_record" "address" {
  for_each = local.address_entries

  zone_id = local.zone_id
  name    = each.value.name
  type    = strcontains(each.value.address, ":") ? "AAAA" : "A"
  content = each.value.address
  proxied = coalesce(each.value.proxied, false)
  ttl     = each.value.ttl
}

# --- Cloudflare Access (Service Token のみ) ---
resource "cloudflare_zero_trust_access_service_token" "consumer" {
  for_each = toset(var.consumers)

  account_id = local.account_id
  name       = "access-${each.key}"
  duration   = "8760h"
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = { for k, e in local.tunnel_entries : k => e if e.access }

  account_id       = local.account_id
  name             = local.fqdn[each.key]
  domain           = local.fqdn[each.key]
  type             = "self_hosted"
  session_duration = "24h"

  policies = [
    {
      name       = "service-tokens"
      decision   = "non_identity"
      precedence = 1
      include = [
        for token in cloudflare_zero_trust_access_service_token.consumer : {
          service_token = { token_id = token.id }
        }
      ]
    }
  ]
}

output "tunnel_ids" {
  description = "Nix (static.nix) の cloud.oci.cloudflared.tunnels.<key>.id に転記する"
  value       = { for k, t in cloudflare_zero_trust_tunnel_cloudflared.tunnel : k => t.id }
}

output "service_tokens" {
  description = "Access Service Token（consumer 名 -> client_id / client_secret）"
  sensitive   = true
  value = {
    for name, token in cloudflare_zero_trust_access_service_token.consumer :
    name => {
      client_id     = token.client_id
      client_secret = token.client_secret
    }
  }
}
