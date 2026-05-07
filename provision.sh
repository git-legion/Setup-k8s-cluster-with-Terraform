#!/bin/bash
set -e

echo "================================="
echo "🔧 Preparing Node: $(hostname)"
echo "================================="

# 1. Fix DNS and APT (Essential for AWS default VPC networking)
echo "🔹 Configuring DNS and cleaning APT..."
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo rm -rf /var/lib/apt/lists/*
sudo apt update -y --fix-missing

# 2. Install dependencies
echo "🔹 Installing dependencies..."
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https

# 3. Add Docker GPG key and Repository
echo "🔹 Adding Docker repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

# 4. PIN DOCKER VERSION
# RKE 1.4.8 fails with Docker 24+. We pin to 20.10.x for stability.
echo "🐳 Installing supported Docker version (20.10.24)..."
DOCKER_VER="5:20.10.24~3-0~ubuntu-jammy"
sudo apt install -y docker-ce=$DOCKER_VER docker-ce-cli=$DOCKER_VER containerd.io

# 5. Configure Docker for Kubernetes
echo "⚙️ Configuring Docker daemon..."
sudo mkdir -p /etc/docker
echo '{
  "exec-opts": ["native.cgroupdriver=systemd"]
}' | sudo tee /etc/docker/daemon.json

# 6. Restart and Enable Docker
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

# 7. Grant permissions to ubuntu user
sudo usermod -aG docker ubuntu

echo "✅ Node Preparation Complete!"