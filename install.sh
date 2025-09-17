#!/bin/bash

# NetworkMind Cognee Installation Script
# Run this on a fresh Ubuntu VM

set -e  # Exit on any error

echo "🔧 Installing Docker..."

# Update system
sudo apt-get update

# Install required dependencies
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo rm get-docker.sh

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (optional)
sudo usermod -aG docker $USER

echo "🐳 Docker installed successfully!"

echo "📦 Installing docker-compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "☁️ Installing AWS CLI (for ECR if needed)..."
sudo apt-get install -y awscli

echo "🔍 Installing monitoring tools..."
sudo apt-get install -y htop curl wget

echo "🌐 Opening firewall for Cognee..."
sudo ufw allow 8000/tcp

echo "✅ Base installation complete!"

echo ""
echo "🔄 Next steps:"
echo "1. Logout and login again to apply docker group changes"
echo "2. Download environment file:"
echo "   scp .env user@vm:/home/user/"
echo "3. Run docker-compose:"
echo "   docker-compose -f vm-setup/docker-compose.yml up -d"
echo "4. Test Cognee:"
echo "   curl http://localhost:8000/health"

echo ""
echo "📖 For manual setup, see vm-setup/README.md"
