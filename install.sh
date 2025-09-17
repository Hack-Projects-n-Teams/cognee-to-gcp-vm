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

echo "🔧 Setting up environment variables..."

# Prompt for Qdrant credentials
read -p "Enter your Qdrant URL (e.g., https://your-cluster.qdrant.tech): " qdrant_url
read -s -p "Enter your Qdrant API Key: " qdrant_api_key
echo ""

# Create .env file
cat > .env << EOF
# Qdrant Configuration
QDRANT_URL=$qdrant_url
QDRANT_API_KEY=$qdrant_api_key

# Other configurations
DEBUG=false
LOG_LEVEL=info
EOF

echo "✅ Environment variables configured!"

# Add user to docker group if not already
if ! groups $USER | grep -q '\bdocker\b'; then
    sudo usermod -aG docker $USER
    echo "🐳 Added $USER to docker group"
fi

# Start docker service
sudo systemctl start docker
sudo systemctl enable docker

echo "🔥 Starting Cognee services..."
# Use newgrp to apply group changes immediately and run docker-compose
newgrp docker << COMMANDS
docker-compose up --build -d
COMMANDS

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check health
echo "🩺 Checking service health..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Cognee is running successfully!"
    echo "🌐 Access your application at: http://\$(curl -s ifconfig.me):8000"
else
    echo "⚠️  Service may still be starting. Check with: docker-compose logs"
fi

echo "🎉 Installation complete!"
echo ""
echo "One-line restart: docker-compose restart && sleep 10 && curl http://localhost:8000/health"