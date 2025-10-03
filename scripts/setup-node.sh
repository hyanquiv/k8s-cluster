#!/usr/bin/env bash
set -euo pipefail

echo "==> [1/5] Actualizando sistema..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "==> [2/5] Instalando dependencias..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

echo "==> [3/5] Instalando Docker CE..."
# Agregar repositorio oficial de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Agregar tu usuario al grupo docker
sudo usermod -aG docker $USER

echo "==> [4/5] Instalando Kubernetes (kubectl, kubeadm, kubelet)..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "==> [5/5] Deshabilitar swap (requerido por kubelet)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "==> Instalación completada ✅"
echo ""
echo "Ahora en el nodo master ejecuta:"
echo "  sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
echo ""
echo "En cada worker, ejecuta el comando 'kubeadm join ...' que te dará el master."
