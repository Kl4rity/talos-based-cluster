locals {
  # Use the first domain as the primary for naming conventions
  primary_domain = var.domains[0]

  # Extract the first part of the primary domain to use as the gateway identifier
  # e.g., "deliberate.cloud" -> "deliberate"
  gateway_identifier = split(".", local.primary_domain)[0]

  # Build a map of per-domain helpers keyed by domain name
  # e.g., "deliberate.cloud" -> { tls_secret_name = "deliberate-cloud-tls", safe_name = "deliberate-cloud" }
  domain_config = {
    for domain in var.domains : domain => {
      tls_secret_name = "${replace(domain, ".", "-")}-tls"
      safe_name       = replace(domain, ".", "-")
    }
  }
}

# Secret for Cloudflare API Token
resource "kubernetes_manifest" "cloudflare_api_token_secret" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "cloudflare-api-token"
      namespace = "cert-manager"
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

# Wildcard certificate for each domain
resource "kubernetes_manifest" "wildcard_certificate" {
  for_each = local.domain_config

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = each.value.tls_secret_name
      namespace = "default"
    }
    spec = {
      dnsNames = [
        each.key,
        "*.${each.key}"
      ]
      issuerRef = {
        kind = "ClusterIssuer"
        name = "letsencrypt-dns01"
      }
      secretName = each.value.tls_secret_name
    }
  }

  depends_on = [kubernetes_manifest.cilium_gateway, kubernetes_manifest.letsencrypt_dns01_issuer]
}

# Patch cert-manager to use external DNS for ACME challenges
resource "null_resource" "cert_manager_dns_patch" {
  provisioner "local-exec" {
    command = "kubectl patch deployment -n cert-manager cert-manager --type='json' -p='[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--dns01-recursive-nameservers-only\"}, {\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53\"}, {\"op\": \"add\", \"path\": \"/spec/template/spec/dnsConfig\", \"value\": {\"nameservers\": [\"1.1.1.1\", \"8.8.8.8\"]}}]'"
  }

  triggers = {
    # Ensure it runs if the deployment changes or if explicitly requested
    cert_manager_version = "v1.19.2"
  }
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
      listeners = flatten([
        for domain, config in local.domain_config : [
          {
            name     = "https-${config.safe_name}"
            port     = 443
            protocol = "HTTPS"
            hostname = "*.${domain}"
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
                  name  = config.tls_secret_name
                }
              ]
            }
          },
          {
            name     = "http-${config.safe_name}"
            port     = 80
            protocol = "HTTP"
            hostname = "*.${domain}"
            allowedRoutes = {
              namespaces = {
                from = "All"
              }
            }
          },
          {
            name     = "https-${config.safe_name}-apex"
            port     = 443
            protocol = "HTTPS"
            hostname = domain
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
                  name  = config.tls_secret_name
                }
              ]
            }
          },
          {
            name     = "http-${config.safe_name}-apex"
            port     = 80
            protocol = "HTTP"
            hostname = domain
            allowedRoutes = {
              namespaces = {
                from = "All"
              }
            }
          }
        ]
      ])
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
          name  = "CF_API_TOKEN"
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

# Generate secure Harbor admin password if not provided
resource "random_password" "harbor_admin_password" {
  count = var.harbor_admin_password == null ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
}

# Harbor for container registry
resource "helm_release" "harbor" {
  name             = "harbor"
  repository       = "https://helm.goharbor.io"
  chart            = "harbor"
  namespace        = "harbor"
  version          = "1.18.2"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    yamlencode({
      externalUrl = "https://registry.${local.primary_domain}"
      expose = {
        type = "clusterIP"
        tls = {
          enabled = false
        }
      }
      harborAdminPassword = var.harbor_admin_password != null ? var.harbor_admin_password : random_password.harbor_admin_password[0].result
      trivy = {
        enabled = true
      }
    })
  ]
}

# HTTPRoute for Harbor
resource "kubernetes_manifest" "harbor_httproute" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "harbor"
      namespace = "harbor"
    }
    spec = {
      parentRefs = [
        {
          name      = "cilium-gateway"
          namespace = "default"
        }
      ]
      hostnames = ["registry.${local.primary_domain}"]
      rules = [
        {
          matches = [{ path = { type = "PathPrefix", value = "/" } }]
          backendRefs = [
            {
              name = "harbor"
              port = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.harbor]
}
