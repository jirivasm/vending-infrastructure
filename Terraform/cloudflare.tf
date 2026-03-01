# 1. Create the Networking Namespace
resource "kubernetes_namespace" "networking" {
  metadata {
    name = "networking"
  }
}

# 2. Create the Tunnel Secret
resource "kubernetes_secret" "cloudflare_token" {
  metadata {
    name      = "cloudflare-tunnel-token"
    namespace = kubernetes_namespace.networking.metadata[0].name
  }

  type = "Opaque"
  data = {
    token = var.cloudflare_token
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
                name = kubernetes_secret.cloudflare_token.metadata[0].name
                key  = "token"
              }
            }
          }
        }
      }
    }
  }
}