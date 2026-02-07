resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
    labels = merge(var.namespace_labels, {
      name = "jenkins"
    })
  }
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = var.chart_version
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  create_namespace = false
  timeout          = 900
  atomic           = true

  values = [
    file("${path.module}/values.yaml")
  ]
}

data "kubernetes_secret" "jenkins_admin" {
  metadata {
    name      = "${helm_release.jenkins.name}-jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
  depends_on = [helm_release.jenkins]
}
