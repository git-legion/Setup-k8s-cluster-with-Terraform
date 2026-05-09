#!/bin/bash
set -e

echo "================================="
echo "🔧 Preparing Node: $(hostname)"
echo "================================="

# 1. Fix DNS and APT (Essential for AWS networking)
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo rm -rf /var/lib/apt/lists/*
sudo apt update -y --fix-missing

# 2. Install dependencies
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https

# 3. Add Docker Repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

# 4. PIN DOCKER VERSION
# RKE 1.4.8 requires specific Docker versions. 20.10.x is highly stable.
DOCKER_VER="5:20.10.24~3-0~ubuntu-jammy"
sudo apt install -y docker-ce=$DOCKER_VER docker-ce-cli=$DOCKER_VER containerd.io

# 5. Configure Docker for Kubernetes
sudo mkdir -p /etc/docker
echo '{
  "exec-opts": ["native.cgroupdriver=systemd"]
}' | sudo tee /etc/docker/daemon.json

sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

# 6. Grant permissions
sudo usermod -aG docker ubuntu

echo "✅ Docker $(docker --version) installed on $(hostname)"