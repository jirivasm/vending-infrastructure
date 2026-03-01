terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}
provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

# 1. Provision the Master Node (miniPC)
resource "null_resource" "k3s_master" {
  triggers = {
    master_ip = var.master_ip
  }

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = var.master_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Downloading K3s installer...'",
      "curl -sfL https://get.k3s.io -o install.sh",
      "chmod +x install.sh",
      "echo 'Running Master installation...'",
      "echo '${var.ssh_password}' | sudo -S sh -c 'K3S_TOKEN=${var.k3s_token} ./install.sh server --cluster-init --write-kubeconfig-mode 644'",
      "echo 'Master installation complete!'"
    ]
  }
}

# 2. Provision the Worker Nodes (Raspberry Pis)
resource "null_resource" "k3s_workers" {
  depends_on = [null_resource.k3s_master]
  count      = length(var.worker_ips)

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = var.worker_ips[count.index]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Downloading K3s installer...'",
      "curl -sfL https://get.k3s.io -o install.sh",
      "chmod +x install.sh",
      "echo 'Running Worker installation...'",
      "echo '${var.ssh_password}' | sudo -S sh -c 'K3S_URL=https://${var.master_ip}:6443 K3S_TOKEN=${var.k3s_token} ./install.sh'",
      "echo 'Worker joined the cluster!'"
    ]
  }
}
