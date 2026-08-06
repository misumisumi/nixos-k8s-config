variable "vault_address" {
  type        = string
  description = "Vault server address (VIP)"
}

variable "vault_ca_cert_path" {
  type        = string
  description = "Path to Vault CA certificate file for TLS verification"
  default     = ""
}

variable "kubernetes_host" {
  type        = string
  description = "Kubernetes API server URL for Vault k8s auth"
}

variable "kubernetes_ca_cert_path" {
  type        = string
  description = "Path to the Kubernetes CA certificate for ServiceAccount JWT verification"
}

variable "kubernetes_auth_path" {
  type        = string
  description = "Mount path for the Kubernetes auth backend"
  default     = "kubernetes"
}

variable "kubernetes_issuer" {
  type        = string
  description = "Issuer URL for the Kubernetes ServiceAccount JWTs"
  default     = "https://kubernetes.default.svc"
}
