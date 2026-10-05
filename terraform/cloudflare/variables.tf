variable "zone" {
  type        = string
  description = "DNS ゾーン名"
  default     = "misumi-sumi.com"
}

variable "entries" {
  description = <<-EOT
    管理するエントリ。
      - address あり: DNS レコード(A/AAAA)のみ作成
      - address なし: Cloudflare Tunnel を作成(locally-managed) + CNAME で公開
    tunnel の proxied は常に true（プロキシ経由でルーティングされるため）。
  EOT
  type = map(object({
    name    = string
    address = optional(string)
    proxied = optional(bool)
    ttl     = optional(number, 1)
    access  = optional(bool, false)
  }))
  default = {}
}

variable "consumers" {
  type        = list(string)
  description = "Access Service Token を発行する consumer 名"
  default = [
    "sumi",
    "github-actions",
  ]
}
