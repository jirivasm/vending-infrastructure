

resource "kubernetes_manifest" "root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-app"
      namespace = "argocd" # Changed from devops-tools to match your new setup
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "git@github.com:jirivasm/vending-infrastructure.git"
        targetRevision = "HEAD"
        path           = "bootstrap" # Argo will now watch this folder for other apps
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  # Very important: Ensure the SSH secret is ready before the Root App tries to pull from Git
  depends_on = [kubernetes_manifest.github_external_secret, helm_release.argocd]
}