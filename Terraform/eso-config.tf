resource "kubernetes_manifest" "vault_backend" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "vault-backend"
    }
    spec = {
      provider = {
        vault = {
          server  = "http://vault.hashicorp.svc.cluster.local:8200"
          path    = "secret"
          version = "v2"
          auth = {
            # For your home lab, we'll start with Token auth
            # Later, we can upgrade this to Kubernetes Auth (even more secure!)
            tokenSecretRef = {
              name      = "vault-token"
              key       = "token"
              namespace = "external-secrets"
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.external_secrets, helm_release.vault, kubernetes_secret.eso_vault_token]
}
resource "kubernetes_manifest" "github_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "argocd-github-creds"
      namespace = "argocd"
    }
    spec = {
      secretStoreRef = {
        name = "vault-backend"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "argocd-github-creds"
        template = {
          metadata = {
            labels = {
              "argocd.argoproj.io/secret-type" = "repository"
            }
          }
          data = {
            type          = "git"
            url           = "git@github.com:jirivasm/vending-infrastructure.git"
            # Use 'sshPrivateKey' (case sensitive) for SSH connections
            sshPrivateKey = "{{ .ssh_key }}" 
          }
        }
      }
      data = [
        {
          secretKey = "ssh_key" # Local template variable name
          remoteRef = {
            key      = "github-creds"
            property = "ssh-private-key" # Matches the key name in Vault UI
          }
        }
      ]
    }
  }
  lifecycle {
    ignore_changes = [
      # Ignore the fields that the ESO controller automatically fills in
      manifest.spec.target.template.engineVersion,
      manifest.spec.target.template.mergePolicy,
    ]
  }

  depends_on = [kubernetes_manifest.vault_backend]
}
resource "kubernetes_manifest" "scraper_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "argocd-scraper-creds" # Unique Name
      namespace = "argocd"
    }
    spec = {
      secretStoreRef = {
        name = "vault-backend"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "argocd-scraper-creds" # Unique Target Name
        template = {
          metadata = {
            labels = {
              "argocd.argoproj.io/secret-type" = "repository"
            }
          }
          data = {
            type          = "git"
            url           = "git@github.com:jirivasm/WorkSearch.git"
            sshPrivateKey = "{{ .ssh_key }}" 
          }
        }
      }
      data = [
        {
          secretKey = "ssh_key"
          remoteRef = {
            key      = "github-creds"
            property = "ssh-private-key"
          }
        }
      ]
    }
  }
  depends_on = [kubernetes_manifest.vault_backend]
}
resource "kubernetes_secret" "eso_vault_token" {
  metadata {
    name      = "vault-token"
    namespace = "external-secrets" # Ensure this matches the ESO installation
  }

  data = {
    token = var.vault_root_token
  }

  type = "Opaque"
  depends_on = [
    helm_release.external_secrets
  ]
}
