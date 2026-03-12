# 1. Create the Networking Namespace
resource "kubernetes_namespace" "networking" {
  metadata {
    name = "networking"
  }
}

# 2. Create the Tunnel Secret
resource "kubernetes_manifest" "cloudflare_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "cloudflare-tunnel-token"
      namespace = kubernetes_namespace.networking.metadata[0].name
    }
    spec = {
      secretStoreRef = {
        name = "vault-backend"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "cloudflare-tunnel-token" # Name of the secret ESO will create
      }
      data = [
        {
          secretKey = "token" # This is the KEY inside the secret cloudflared will look for
          remoteRef = {
            key      = "cloudflare" # The path in Vault UI
            property = "cloudflare" # The field name inside Vault
          }
        }
      ]
    }
  }
}

# 3. Deploy the Cloudflared Agent
resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.networking.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cloudflared"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }

      spec {
        container {
          name  = "cloudflared"
          image = "cloudflare/cloudflared:latest"
          args  = ["tunnel", "--no-autoupdate", "run"]

          env {
            name = "TUNNEL_TOKEN"
            value_from {
              secret_key_ref {
                name = "cloudflare-tunnel-token"
                key  = "token"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_manifest.cloudflare_external_secret]
}