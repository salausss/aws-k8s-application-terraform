locals {
  k8s_path = "${path.module}/../../src/k8s"

  manifests = flatten([
    for f in fileset(local.k8s_path, "*.yaml") : [
      for idx, doc in split("---", file("${local.k8s_path}/${f}")) : {
        key = "${f}-${idx}"
        content = try(
          yamldecode(trimspace(doc)),
          error("❌ YAML ERROR in file: ${f} (doc index: ${idx})")
        )
      }
      if trimspace(doc) != ""
    ]
  ])
}

resource "kubernetes_manifest" "this" {
  for_each = local.manifests
  manifest  = each.value
}