variable "ssh_user" {
  description = "The shared SSH username for all nodes"
  type        = string
}

variable "ssh_password" {
  description = "SSH password for your nodes"
  type        = string
  sensitive   = true
}

variable "master_ip" {
  description = "IP address of the x86 miniPC"
  type        = string
}

variable "worker_ips" {
  description = "IP addresses of the ARM64 Raspberry Pis"
  type        = list(string)
}

variable "k3s_token" {
  description = "Pre-shared secret for cluster nodes to join"
  type        = string
  sensitive   = true
  default     = "SuperSecretK3sToken123!" 
}
variable "minio_user" {
  description = "MinIO Access Key"
  type        = string
  sensitive   = true
}
variable "minio_password" {
  description = "MinIO Secret Key"
  type        = string
  sensitive   = true
}