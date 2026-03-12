# ==========================================
# 3. Install Longhorn via Helm
# ==========================================
resource "helm_release" "longhorn" {
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  namespace        = "longhorn-system"
  create_namespace = true
  version          = "1.7.0" 

  # Wait for the nodes to be ready before installing
  depends_on = [null_resource.k3s_workers]
}
# ==========================================
# 4. Install ArgoCD via Helm
# ==========================================

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.3.4" # Latest stable version

  repository_key_file        = "" 
  repository_cert_file       = ""
  repository_ca_file         = ""
  
    values = [
    # Just point to the standard values (Ingress, Resources, etc.)
    file("../values/argo-values.yaml") 
  ]
  # Ensure the cluster and storage are ready first
  depends_on = [helm_release.longhorn]
}
# ==========================================
# 4. Install Hashicorp Vault via Helm
# ==========================================
resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = "hashicorp"
  create_namespace = true

  values = [
    <<-EOT
    server:
      # Use Longhorn for persistent storage
      dataStorage:
        enabled: true
        size: 5Gi
        storageClass: "longhorn"
      
      # This is the Helm-level UI setting
      ui:
        enabled: true
        serviceType: ClusterIP
      
      standalone:
        enabled: true
        # This nested 'config' block is strictly for Vault's HCL syntax
        config: |
          ui = true
          listener "tcp" {
            tls_disable = 1
            address     = "[::]:8200"
            cluster_address = "[::]:8201"
          }
          storage "file" {
            path = "/vault/data"
          }
    EOT
  ]

  # Ensure Longhorn is ready to provide the volume first!
  depends_on = [helm_release.longhorn]
}
# ==========================================
# 5. Install External Secrets Operator
# ==========================================
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "0.9.13" # Or latest stable

  # We need the Custom Resource Definitions (CRDs) for this to work
  set {
    name  = "installCRDs"
    value = "true"
  }
  values = [
    <<-EOT
    resources:
      requests:
        cpu: 10m
        memory: 64Mi
      limits:
        cpu: 50m
        memory: 128Mi
    EOT
  ]

  # Ensure the cluster is ready
  depends_on = [null_resource.k3s_workers]
}
