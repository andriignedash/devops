resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = merge(var.namespace_labels, {
      name = "argocd"
    })
  }
}

resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  timeout          = 900
  atomic           = true

  values = [
    file("${path.module}/values.yaml")
  ]
}

data "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argo_cd]
}
