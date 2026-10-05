entries = {
  # LiteLLM: address 無し → Tunnel + Access で保護
  # NOTE: Cloudflare の Universal SSL は 1 階層のみ対応のため "llm" (llm.misumi-sumi.com)
  "llm" = {
    name   = "llm"
    access = true
  },
  # Paseo relay: address 無し → Tunnel + CNAME のみ（Access は付けない）
  # native client が service token を出せないため、E2EE を前提に open relay として公開する。
  # NOTE: Cloudflare の Universal SSL は 1 階層のみ対応のため "relay" (relay.misumi-sumi.com)
  "relay" = {
    name = "relay"
  },
  "wg.oci" = {
    name    = "wg.oci",
    address = "129.225.192.86",
    proxied = false,
  }
  "hs.oci" = {
    name    = "hs.oci",
    address = "129.225.192.86",
    proxied = false,
  }
  "*.oci" = {
    name    = "*.oci",
    address = "129.225.192.86",
    proxied = true,
  }
}
