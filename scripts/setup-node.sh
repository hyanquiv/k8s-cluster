#!/usr/bin/env bash
set -euo pipefail

echo "==> Actualizando sistema..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "==> Instalando dependencias..."
sudo apt-get install -y \
    curl wget git apt-transport-https \
    ca-certificates gnupg lsb-release software-properties-common

echo "==> Instalando Docker..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker <<EONG
echo "Docker instalado: $(docker --version)"
EONG

echo "==> Instalando kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
echo "kubectl instalado: $(kubectl version --client --output=yaml | grep gitVersion)"

echo "==> Instalando k3s (servidor o agente según el rol)"
# ⚠️ Si esta máquina es el MASTER
# curl -sfL https://get.k3s.io | sh -

# ⚠️ Si esta máquina es un AGENTE, reemplazar <MASTER_IP> y <TOKEN>
# curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<TOKEN> sh -

echo "==> Instalación base completada."
