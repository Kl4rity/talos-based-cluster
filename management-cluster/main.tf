terraform {
  required_providers {
    hetznercloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.33"
    }
  }
}

provider "hetznercloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "management" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.location
  image       = var.image
  ssh_keys    = [var.ssh_key_name]
  labels = {
    role     = "management"
    cluster  = "argocd"
    terraform = "true"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file(var.ssh_private_key_path)
  }

  user_data = <<-EOT
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - curl
      - wget
      - git
  EOT

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_VERSION=1.35.0+k3s1 sh -",
      "mkdir -p /root/.kube",
      "cp /etc/rancher/k3s/k3s.yaml /root/.kube/config",
      "chmod 600 /root/.kube/config",
      "export IP=$(hostname -I | awk '{print $1}')",
      "sed -i 's|127.0.0.1|'\"$IP\"'|g' /root/.kube/config"
    ]
  }

  provisioner "local-exec" {
    command = "ssh-keygen -R ${self.ipv4_address} 2>/dev/null || true && scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} root@${self.ipv4_address}:/root/.kube/config ${path.module}/bootstrap/kubeconfig && chmod 600 ${path.module}/bootstrap/kubeconfig"
  }
}
