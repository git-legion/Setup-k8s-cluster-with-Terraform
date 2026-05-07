#!/bin/bash
set -e

echo "================================="
echo "🚀 Starting RKE Provisioning"
echo "================================="

############################################
# Fix DNS (important for AWS networking)
############################################
echo "🔧 Fixing DNS..."

sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'

############################################
# Fix APT corruption issues
############################################
echo "🔧 Fixing APT issues..."

sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /var/cache/apt/archives/*
sudo mkdir -p /var/lib/apt/lists/partial

sudo apt clean
sudo apt update -y --fix-missing

############################################
# Install dependencies
############################################
echo "🔹 Installing dependencies..."

sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https

############################################
# Install Docker (NON-INTERACTIVE)
############################################
echo "🐳 Installing Docker..."

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

sudo apt install -y \
docker-ce=5:23.0.6-1~ubuntu.22.04~jammy \
docker-ce-cli=5:23.0.6-1~ubuntu.22.04~jammy \
containerd.io

############################################
# Configure Docker
############################################
echo "⚙️ Configuring Docker..."

sudo mkdir -p /etc/docker

echo '{
  "exec-opts": ["native.cgroupdriver=systemd"]
}' | sudo tee /etc/docker/daemon.json

sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable docker
sudo systemctl restart docker

sudo usermod -aG docker ubuntu

############################################
# Verify Docker
############################################
echo "✅ Verifying Docker..."

docker --version

############################################
# Install RKE
############################################
echo "☸️ Installing RKE..."

wget -q https://github.com/rancher/rke/releases/download/v1.4.8/rke_linux-amd64

chmod +x rke_linux-amd64
sudo mv rke_linux-amd64 /usr/local/bin/rke

############################################
# Verify RKE
############################################
echo "✅ Verifying RKE..."

rke --version

############################################
# Run RKE cluster
############################################
echo "🚀 Running RKE cluster..."

cd /home/ubuntu

rke up

############################################
# Setup kubectl
############################################
echo "⚙️ Configuring kubectl..."

export KUBECONFIG=/home/ubuntu/kube_config_cluster.yml

echo 'export KUBECONFIG=/home/ubuntu/kube_config_cluster.yml' >> ~/.bashrc

############################################
# Verify cluster
############################################
echo "🎯 Cluster status..."

kubectl get nodes || true

echo "================================="
echo "✅ RKE Cluster Setup Complete!"
echo "================================="