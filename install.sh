#!/bin/bash

# Exit on any error
set -e

echo "🔧 Installing Docker..."
# Update package list
sudo apt-get update -qq

# Install prerequisites
sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release jq

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    echo "🐳 Docker installed successfully!"
else
    echo "🐳 Docker already installed!"
fi

echo "📦 Installing docker-compose..."
# Install docker-compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "☁️ Installing AWS CLI (for ECR if needed)..."
sudo apt-get install -y -qq awscli

echo "🔍 Installing monitoring tools..."
sudo apt-get install -y -qq htop curl wget

echo "🌐 Installing and configuring firewall for Cognee..."
# Install ufw if not present
if ! command -v ufw &> /dev/null; then
    echo "Installing ufw..."
    sudo apt-get install -y -qq ufw
fi

# Configure firewall
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 8000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo "🔥 Starting Cognee services..."
# Build and start the containers
docker-compose up --build -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check health
echo "🩺 Checking service health..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Cognee is running successfully!"
    echo "🌐 Access your application at: http://$(curl -s ifconfig.me):8000"
else
    echo "⚠️  Service may still be starting. Check with: docker-compose logs"
fi

echo "🎉 Installation complete!"
echo ""
echo "Useful commands:"
echo "  Check status: docker-compose ps"
echo "  View logs:    docker-compose logs -f"
echo "  Stop:         docker-compose down"
echo "  Restart:      docker-compose restart"