#--------- Create ArgoCD --------------------#
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace        = "argocd"
  create_namespace = true

  values = [<<EOF
server:
  service:
    type: LoadBalancer
EOF
  ]

  timeout = 600
}

#--------- Create Application Through ArgoCD -------------------#

resource "kubernetes_manifest" "taskflow_app" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "taskflow"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/salausss/three-tier-application"
        targetRevision = "main"
        path           = "src/k8s/helm/taskflow"

        helm = {
          valueFiles = [
            "../../values/dev/values.yaml"
          ]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "app"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}