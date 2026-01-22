

resource "kubernetes_manifest" "cilium_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "cilium-gateway"
      namespace = "default"
      annotations = {
        "cert-manager.io/issuer" = "letsencrypt-dns01"
      }
    }
    spec = {
      gatewayClassName = "cilium"
      infrastructure = {
        annotations = {
          "load-balancer.hetzner.cloud/location" = "fsn1"
          "load-balancer.hetzner.cloud/name" = "deliberate-gateway"
          "load-balancer.hetzner.cloud/uses-proxyprotocol" = "true"
        }
      }
      listeners = [
        {
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
          hostname = "*.deliberate.cloud"
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                group = ""
                kind  = "Secret"
                name  = "deliberate-cloud-tls"
              }
            ]
          }
        },
        {
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
          hostname = "*.deliberate.cloud"
          name     = "http"
          port     = 80
          protocol = "HTTP"
        }
      ]
    }
  }
}







variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}
