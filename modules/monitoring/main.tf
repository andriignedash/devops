resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = merge(var.namespace_labels, {
      name = "monitoring"
    })
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false
  timeout          = 900
  atomic           = true

  values = [
    file("${path.module}/values.yaml")
  ]
}

data "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "${helm_release.kube_prometheus_stack.name}-grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  depends_on = [helm_release.kube_prometheus_stack]
}
