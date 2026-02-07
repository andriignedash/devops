resource "null_resource" "eks_ready" {
  triggers = {
    cluster_name = module.eks.cluster_name
    region       = var.aws_region
  }
  depends_on = [module.eks]

  provisioner "local-exec" {
    command     = <<-EOT
      aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} && \
      kubectl wait --for=condition=Ready nodes --all --timeout=600s && \
      kubectl wait --for=condition=Available deployment/coredns -n kube-system --timeout=600s && \
      kubectl wait -n kube-system --for=condition=Ready pod -l k8s-app=aws-node --timeout=600s && \
      (kubectl wait -n kube-system --for=condition=Ready pod -l app.kubernetes.io/name=aws-ebs-csi-driver --timeout=300s || true)
    EOT
    interpreter = ["bash", "-c"]
  }
}
