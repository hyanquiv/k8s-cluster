#!/bin/bash

# =========================================================
# Script robusto y actualizado de instalación:
# Docker, containerd, Kubernetes, Helm, K9s
# Configuración de CRI v1 lista para kubeadm
# =========================================================

set -e

echo "==== ACTUALIZANDO EL SISTEMA ===="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "==== INSTALANDO DEPENDENCIAS ===="
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# =========================================================
# INSTALACIÓN DE DOCKER
# =========================================================
echo "==== INSTALANDO DOCKER ===="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Configuración para usar Docker sin sudo
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

echo "==== DOCKER INSTALADO ===="
docker --version

# =========================================================
# CONFIGURACIÓN DE CONTAINERD PARA KUBERNETES CRI v1
# =========================================================
echo "==== CONFIGURANDO CONTAINERD PARA CRI v1 ===="
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo systemctl status containerd --no-pager

# =========================================================
# DESACTIVAR SWAP
# =========================================================
echo "==== DESACTIVANDO SWAP ===="
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# =========================================================
# CONFIGURACIÓN DE KERNEL Y RED PARA KUBERNETES
# =========================================================
echo "==== CONFIGURANDO KERNEL Y RED ===="
sudo sysctl net.ipv4.ip_forward=1
sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# =========================================================
# INSTALACIÓN DE KUBERNETES
# =========================================================
echo "==== INSTALANDO KUBERNETES ===="
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "==== KUBERNETES INSTALADO ===="
kubectl version --client --short
kubeadm version

# =========================================================
# INSTALACIÓN DE HELM
# =========================================================
echo "==== INSTALANDO HELM ===="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# =========================================================
# INSTALACIÓN DE K9S
# =========================================================
echo "==== INSTALANDO K9S ===="
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
curl -Lo k9s.tar.gz https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz
tar -xzf k9s.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz
k9s version

# =========================================================
# VERIFICACIÓN DEL SISTEMA
# =========================================================
echo "==== VERIFICANDO ESTADO ===="
docker info | grep "Server Version"
systemctl status containerd --no-pager | head -n 5
systemctl status kubelet | head -n 5
kubectl version --client
helm version
k9s version

# =========================================================
# INSTRUCCIONES POST-INSTALACIÓN
# =========================================================
echo "==== LISTO PARA INICIALIZAR EL MASTER ===="
echo "Ejecuta en el nodo master:"
echo "sudo kubeadm init --pod-network-cidr=192.168.0.0/16"
echo "Luego aplica Calico:"
echo "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
echo "Después une los nodos worker con 'kubeadm join ...'"
echo "Recuerda reiniciar la sesión o usar 'newgrp docker' para usar Docker sin sudo."
