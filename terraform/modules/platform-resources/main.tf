

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









resource "kubernetes_manifest" "hetzner_dns_api_token_secret" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "hetzner-dns-api-token"
      namespace = "cert-manager"
    }
    type = "Opaque"
    data = {
      api-token = base64encode(var.hetzner_dns_api_token)
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_dns01_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-dns01"
    }
    spec = {
      acme = {
        server         = "https://acme-v02.api.letsencrypt.org/directory"
        email          = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-dns01-key"
        }
        solvers = [
          {
            dns01 = {
              webhook = {
                groupName  = "dns01.deliberate.cloud"
                solverName = "lexicon"
                config = {
                  provider = "hetzner"
                  apiTokenRef = {
                    name = "hetzner-dns-api-token"
                    key  = "api-token"
                  }
                }
              }
            }
          }
        ]
      }
    }
  }
}
