resource "kubernetes_manifest" "cluster_issuer_letsencrypt" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-http01"
    }
    spec = {
      acme = {
        server         = "https://acme-v02.api.letsencrypt.org/directory"
        email          = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-http01-key"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [
                  {
                    name      = "cilium-gateway"
                    namespace = "default"
                    group     = "gateway.networking.k8s.io"
                    kind      = "Gateway"
                  }
                ]
              }
            }
          }
        ]
      }
    }
  }
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}
