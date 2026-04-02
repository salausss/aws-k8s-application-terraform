resource "helm_release" "taskflow" {
  name       = "taskflow"
  chart      = "${path.root}/../../k8s"
  namespace  = "app"

  create_namespace = false

  values = [
    file("${path.root}/../../k8s/values/dev.yaml")
  ]

  # 🔥 Important for stability
  timeout          = 600
  atomic           = true
  cleanup_on_fail  = true
  dependency_update = true
}