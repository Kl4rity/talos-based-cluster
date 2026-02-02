locals {
  # Extract the first part of the domain to use as the gateway identifier
  # e.g., "deliberate.cloud" -> "deliberate"
  gateway_identifier = split(".", var.domain_name)[0]

  # Create a safe name for the TLS secret by replacing dots with hyphens
  # e.g., "deliberate.cloud" -> "deliberate-cloud-tls"
  tls_secret_name = "${replace(var.domain_name, ".", "-")}-tls"
}

# Secret for Cloudflare API Token
resource "kubernetes_manifest" "cloudflare_api_token_secret" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "cloudflare-api-token"
      namespace = "kube-system"
    }
    type = "Opaque"
    data = {
      api-token = base64encode(var.cloudflare_api_token)
    }
  }
}

# ClusterIssuer for Let's Encrypt DNS-01 validation via Cloudflare
resource "kubernetes_manifest" "letsencrypt_dns01_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-dns01"
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
resource "kubernetes_manifest" "wildcard_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.tls_secret_name
      namespace = "default"
    }
    spec = {
      dnsNames = [
        var.domain_name,
        "*.${var.domain_name}"
      ]
      issuerRef = {
        kind = "ClusterIssuer"
        name = "letsencrypt-dns01"
      }
      secretName = local.tls_secret_name
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
          "load-balancer.hetzner.cloud/location"           = "fsn1"
          "load-balancer.hetzner.cloud/name"               = "${local.gateway_identifier}-gateway"
          "load-balancer.hetzner.cloud/uses-proxyprotocol" = "true"
        }
      }
      listeners = [
        {
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          hostname = "*.${var.domain_name}"
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
                name  = local.tls_secret_name
              }
            ]
          }
        },
        {
          name     = "http"
          port     = 80
          protocol = "HTTP"
          hostname = "*.${var.domain_name}"
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

# External DNS for Cloudflare
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.14.3"

  values = [
    yamlencode({
      provider = "cloudflare"
      env = [
        {
          name = "CF_API_TOKEN"
          value = var.cloudflare_api_token
        }
      ]
      policy = "sync"
      sources = [
        "gateway-httproute",
        "service",
        "ingress"
      ]
    })
  ]
}

# Harbor for container registry
resource "helm_release" "harbor" {
  name       = "harbor"
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  namespace  = "harbor"
  version    = "1.18.2"
  create_namespace = true
  atomic = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      externalUrl = "registry.deliberate.cloud"
      trivy = {
        enabled = true
      }
    })
  ]
}
