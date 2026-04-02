locals {
  manifests = {
    for f in fileset("${path.root}/../../src/k8s/", "*.yaml") :
    f => yamldecode(file("${path.root}/../../src/k8s/${f}"))
  }
}

resource "kubernetes_manifest" "this" {
  for_each = local.manifests
  manifest  = each.value
}