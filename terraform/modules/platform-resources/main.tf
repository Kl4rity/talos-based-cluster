# Secret for Cloudflare API Token
resource "kubernetes_manifest" "cloudflare_api_token_secret" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "cloudflare-api-token"
      namespace = "default"
    }
    type = "Opaque"
    data = {
      api-token = base64encode(var.cloudflare_api_token)
    }
  }
}

# Issuer for Let's Encrypt DNS-01 validation via Cloudflare
resource "kubernetes_manifest" "letsencrypt_dns01_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "letsencrypt-dns01"
      namespace = "default"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-dns01-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = "cloudflare-api-token"
                  key  = "api-token"
                }
              }
            }
          }
        ]
      }
    }
  }
}

# Certificate resource to issue the wildcard certificate
resource "kubernetes_manifest" "deliberate_cloud_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "deliberate-cloud-tls"
      namespace = "default"
    }
    spec = {
      dnsNames = [
        "deliberate.cloud",
        "*.deliberate.cloud"
      ]
      issuerRef = {
        kind = "Issuer"
        name = "letsencrypt-dns01"
      }
      secretName = "deliberate-cloud-tls"
    }
  }

  depends_on = [kubernetes_manifest.cilium_gateway, kubernetes_manifest.letsencrypt_dns01_issuer]
}

# Gateway for Cilium with TLS termination
resource "kubernetes_manifest" "cilium_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "cilium-gateway"
      namespace = "default"
    }
    spec = {
      gatewayClassName = "cilium"
      infrastructure = {
        annotations = {
          "load-balancer.hetzner.cloud/location"      = "fsn1"
          "load-balancer.hetzner.cloud/name"          = "deliberate-gateway"
          "load-balancer.hetzner.cloud/uses-proxyprotocol" = "true"
        }
      }
      listeners = [
        {
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          hostname = "*.deliberate.cloud"
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
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
          name     = "http"
          port     = 80
          protocol = "HTTP"
          hostname = "*.deliberate.cloud"
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        }
      ]
    }
  }
}
