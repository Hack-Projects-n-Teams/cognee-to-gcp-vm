#!/bin/bash

# NetworkMind Cognee VM Setup Script
# One-command installation for fresh Ubuntu VMs
# This script handles everything: installs Docker, prompts for config, and launches Cognee

set -e  # Exit on any error

echo "🚀 Starting NetworkMind Cognee VM Setup..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root - this is fine, but note that docker group changes won't apply"
fi

print_status "🔧 Installing Docker and dependencies..."

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

print_status "🐳 Docker installed successfully!"

print_status "📦 Installing docker-compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

print_status "☁️ Installing AWS CLI (optional)..."
sudo apt-get install -y awscli || print_warning "AWS CLI installation failed - optional dependency"

print_status "🔍 Installing monitoring tools..."
sudo apt-get install -y htop curl wget

print_status "🌐 Opening firewall port 8000 for Cognee..."
sudo ufw allow 8000/tcp || print_warning "UFW not available - firewall rules may need manual setup"

print_status "✅ Base installation complete!"
echo ""

print_status "🔧 Configuring Cognee environment..."

# Check if .env already exists
if [ -f ".env" ]; then
    print_warning ".env file already exists - using existing configuration"
else
    print_status "Creating .env file..."

    # Prompt for QDrant configuration
    echo -e "${YELLOW}Please provide your QDrant configuration:${NC}"
    echo -n "QDrant URL (e.g., https://xyz-abc.cloud.qdrant.io:6333): "
    read -r qdrant_url

    echo -n "QDrant API Key: "
    read -r -s qdrant_key
    echo ""  # New line after hidden input

    # Validate input
    if [ -z "$qdrant_url" ] || [ -z "$qdrant_key" ]; then
        print_error "Both QDrant URL and API Key are required!"
        exit 1
    fi

    # Create .env file
    cat > .env << EOF
# Cognee Environment Configuration
QDRANT_URL=$qdrant_url
QDRANT_API_KEY=$qdrant_key
EOF

    print_status ".env file created successfully"
fi

echo ""
print_status "🚀 Launching Cognee with Docker Compose..."

# Add current user to docker group (optional, but try it)
sudo usermod -aG docker $USER || print_warning "Could not add user to docker group"

# Launch Cognee
docker-compose up -d

print_status "⏳ Waiting for Cognee to start up..."
sleep 10

print_status "🏥 Running health check..."
if curl -f -s http://localhost:8000/health > /dev/null; then
    print_status "✅ Cognee is running and healthy!"
    print_status "🌐 Cognee API is available at: http://localhost:8000"
else
    print_error "❌ Health check failed - Cognee may not have started properly"
    print_status "Check logs with: docker-compose logs"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Useful commands:"
echo "  • View logs: docker-compose logs -f"
echo "  • Restart: docker-compose restart"
echo "  • Stop: docker-compose down"
echo "  • Health check: curl http://localhost:8000/health"
echo ""
print_warning "Remember to logout/login if you want docker commands without sudo"
