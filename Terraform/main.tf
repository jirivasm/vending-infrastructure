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

#Provision the first master node 
resource "null_resource" "k3s_init" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file("C:/Users/jiriv/.ssh/home-lab-key") # Path to your local private key
    host        = var.master_ips[0]
  }

  provisioner "remote-exec" {
    inline = [
      #"echo 'SSH is working perfectly!'"
      "set -x",
      "curl -sfL https://get.k3s.io | K3S_TOKEN='${var.k3s_token}' sh -s - server --cluster-init --tls-san ${var.vip} --write-kubeconfig-mode 644"
    ]
  }
}
#Provision the other master nodes
resource "null_resource" "k3s_masters_join" {
  count      = length(var.master_ips) - 1
  depends_on = [null_resource.k3s_init]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file("C:/Users/jiriv/.ssh/home-lab-key")
    host        = var.master_ips[count.index + 1]
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_TOKEN='${var.k3s_token}' sh -s - server --server https://${var.master_ips[0]}:6443 --tls-san ${var.vip} --write-kubeconfig-mode 644"
    ]
  }
}



#Provision the Worker Nodes 
resource "null_resource" "k3s_workers_join" {
  count      = length(var.worker_ips)
  depends_on = [null_resource.k3s_masters_join]

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password # Uses the password from your .tfvars
    host     = var.worker_ips[count.index]
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_URL=https://${var.vip}:6443 K3S_TOKEN='${var.k3s_token}' sh -s - agent"
    ]
  }
}
