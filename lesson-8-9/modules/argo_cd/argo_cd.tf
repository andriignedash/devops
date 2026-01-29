resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      name = var.namespace
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      namespace = var.namespace
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

resource "helm_release" "argo_apps" {
  name      = "argo-apps"
  chart     = "${path.module}/charts/argo-apps"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/charts/argo-apps/values.yaml", {
      gitops_repo_url  = var.gitops_repo_url
      gitops_branch    = var.gitops_branch
      app_namespace    = var.app_namespace
      app_chart_path   = var.app_chart_path
      argocd_namespace = var.namespace
    })
  ]

  depends_on = [
    helm_release.argocd
  ]
}
