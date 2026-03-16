resource "kubernetes_secret" "longhorn_minio_secret" {
  metadata {
    name      = "minio-backup-secret"
    namespace = "longhorn-system"
  }

  # Use 'data' for base64 encoded strings or 'string_data' for plain text
  data = {
    AWS_ACCESS_KEY_ID     = var.minio_user     # Your MinIO Username
    AWS_SECRET_ACCESS_KEY = var.minio_password     # Your MinIO Password
    AWS_ENDPOINTS         = "http://10.0.0.34:9000"
  }

  type = "Opaque"
}
resource "kubernetes_manifest" "longhorn_setting_backup_target" {
  manifest = {
    apiVersion = "longhorn.io/v1beta2"
    kind       = "Setting"
    metadata = {
      name      = "backup-target"
      namespace = "longhorn-system"
    }
    value = "s3://longhornbackup@us-east-1/?endpoint=http://10.0.0.34:9000"

    
    }
    field_manager  {
    force_conflicts = true
  }
  depends_on = [helm_release.longhorn]
}
  
resource "kubernetes_manifest" "longhorn_setting_backup_secret" {
  manifest = {
    apiVersion = "longhorn.io/v1beta2"
    kind       = "Setting"
    metadata = {
      name      = "backup-target-credential-secret"
      namespace = "longhorn-system"
    }
    value = "minio-backup-secret"
  }
    field_manager  {
    force_conflicts = true
    }
}
resource "kubernetes_storage_class" "longhorn_retain" {
  metadata {
    name = "longhorn-retain"
  }
  storage_provisioner = "driver.longhorn.io"
  reclaim_policy      = "Retain" # This prevents data loss on destroy
  volume_binding_mode = "Immediate"
  
  parameters = {
    numberOfReplicas    = "3"
    staleReplicaTimeout = "2880"
    fromBackup          = ""
  }

  depends_on = [helm_release.longhorn]
}
