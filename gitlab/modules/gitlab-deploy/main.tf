terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  primary_domain = var.domains[0]
  gitlab_url     = "https://gitlab.${local.primary_domain}"
  registry_url   = "https://registry.${local.primary_domain}"
}

# Create Kubernetes namespace for GitLab first
resource "kubernetes_namespace" "gitlab" {
  count = var.enable_gitlab ? 1 : 0

  metadata {
    name = "gitlab"
  }
}

# Create Kubernetes secret for GitLab initial root password
resource "kubernetes_secret" "gitlab_initial_root_password" {
  count = var.enable_gitlab && var.gitlab_root_password != null ? 1 : 0

  metadata {
    name      = "gitlab-initial-root-password"
    namespace = kubernetes_namespace.gitlab[0].metadata[0].name
  }

  data = {
    password = var.gitlab_root_password
  }

  type = "Opaque"
}

# GitLab Helm Release on the dedicated K3s instance
resource "helm_release" "gitlab_ce" {
  count      = var.enable_gitlab ? 1 : 0
  name       = "gitlab"
  repository = "https://charts.gitlab.io/"
  chart      = "gitlab"
  version    = var.gitlab_chart_version
  namespace  = kubernetes_namespace.gitlab[0].metadata[0].name
  create_namespace = false
  timeout               = 900
  render_subchart_notes = true
  wait                  = true
  atomic                = false
  dependency_update     = false
  force_update          = false
  recreate_pods         = false
  replace               = false
  skip_crds             = false
  reset_values          = false
  disable_webhooks      = false
  reuse_values          = false
  verify                = false
  lint                  = false
  max_history           = 0
  pass_credentials      = false
  wait_for_jobs         = false
  cleanup_on_fail       = false
  disable_crd_hooks     = false
  disable_openapi_validation = false

  values = [
    templatefile("${path.module}/values.yaml", {
      domain            = local.primary_domain
      letsencrypt_email = var.letsencrypt_email
    })
  ]

  depends_on = [
    kubernetes_namespace.gitlab,
    kubernetes_secret.gitlab_initial_root_password
  ]
}
