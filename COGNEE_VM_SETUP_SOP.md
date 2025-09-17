# Cognee VM Setup SOP

**Purpose:** Deploy Cognee service on a fresh Ubuntu GCP VM for production use.

**Prerequisites:**
- GCP Ubuntu VM (Ubuntu 20.04+)
- Sudo access
- GitHub access
- QDrant cloud instance URL and API key

**Estimated Time:** 10-15 minutes

---

## Step 1: VM Provisioning

```bash
# Create GCP VM (example - adjust as needed)
gcloud compute instances create cognee-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --boot-disk-size=30GB \
  --tags=cognee
```

## Step 2: Initial VM Setup

```bash
# Connect to VM via GCP Cloud Shell
# (GCP Cloud Shell provides direct SSH access to VMs)

# Update system
sudo apt-get update

# Install Git (required for cloning)
sudo apt-get install -y git
```

## Step 3: Docker Installation and Setup

```bash
# Install Docker
sudo apt-get install -y docker.io docker-compose git ufw

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (requires newgrp or logout/login)
sudo usermod -aG docker $USER

# Apply group changes immediately (alternative to logout/login)
newgrp docker
```

## Step 4: Repository Deployment

```bash
# Clean any previous attempts
rm -rf cognee-to-gcp-vm

# Clone the deployment repository
git clone https://github.com/Hack-Projects-n-Teams/cognee-to-gcp-vm.git

# Navigate to repository
cd cognee-to-gcp-vm
```

## Step 5: Environment Configuration

```bash
# Create environment file with QDrant credentials
cat > .env << EOF
QDRANT_URL=YOUR_QDRANT_URL_HERE
QDRANT_API_KEY=YOUR_QDRANT_API_KEY_HERE
EOF

# Example:
# QDRANT_URL=https://xyz-abc.cloud.qdrant.io:6333
# QDRANT_API_KEY=qdrant-api-key-from-cloud-dashboard
```

## Step 6: Fix Docker Image

**Important:** The default image name may be incorrect.

```bash
# Update to correct Cognee Docker image
sed -i 's|cognics/cognee:latest|cognee/cognee:latest|g' docker-compose.yml

# Pull the correct image
docker pull cognee/cognee:latest
```

## Step 7: Firewall Configuration

```bash
# Enable firewall with required ports
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 8000/tcp

# Optional: Allow additional ports for your infra
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Step 8: Service Deployment

```bash
# Start Cognee services
docker-compose up --build -d

# Wait for initialization (required)
sleep 60
```

## Step 9: Verification

```bash
# Check service status
docker-compose ps

# Health check
curl -f http://localhost:8000/health

Expected response:
{"status":"ready","health":"degraded","version":"0.3.3-local"}

# View recent logs
docker-compose logs --tail=20
```

## Step 10: External Access

```bash
# Get external IP for other services to connect
curl -s ifconfig.me
# OR
gcloud compute instances list | grep cognee-vm

# Cognee will be accessible at:
# http://YOUR_EXTERNAL_IP:8000
```

---

## Commands Summary

```bash
# One-time setup commands (run in sequence):
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git ufw
sudo systemctl start docker && sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Deployment commands:
rm -rf cognee-to-gcp-vm
git clone https://github.com/Hack-Projects-n-Teams/cognee-to-gcp-vm.git
cd cognee-to-gcp-vm
cat > .env << EOF
QDRANT_URL=https://your-qdrant-instance:6333
QDRANT_API_KEY=your-api-key
EOF
sed -i 's|cognics/cognee:latest|cognee/cognee:latest|g' docker-compose.yml
docker pull cognee/cognee:latest
sudo ufw --force enable && sudo ufw allow ssh && sudo ufw allow 8000/tcp
docker-compose up --build -d
sleep 60
curl http://localhost:8000/health
```

---

## Troubleshooting

### Docker Permission Issues
```bash
# If commands fail with permission denied:
newgrp docker
# Or logout and login again
```

### Image Pull Issues
```bash
# If wrong image name:
docker search cognee
# Look for correct image: cognee/cognee
```

### Service Won't Start
```bash
# Check detailed logs:
docker-compose logs cognee

# Restart services:
docker-compose down && docker-compose up -d
```

### QDrant Connection Issues
```bash
# Verify QDrant connectivity:
curl -H "api-key: YOUR_QDRANT_API_KEY" YOUR_QDRANT_URL/collections

# Check .env file syntax:
cat .env
```

## Post-Deployment Operations

```bash
# Service management:
docker-compose restart    # Restart services
docker-compose down       # Stop services
docker-compose logs -f    # Follow logs
docker-compose ps         # Check status

# Update deployment:
cd cognee-to-gcp-vm
git pull origin master
docker-compose down && docker-compose up --build -d
```

## Security Notes

- Firewall is enabled with minimal ports (SSH + 8000)
- Docker group membership allows non-root container management
- Environment variables contain sensitive API keys
- Consider additional security hardening for production

---

**Success Indicators:**
- ✅ `docker-compose ps` shows container "Up"
- ✅ `curl http://localhost:8000/health` returns JSON
- ✅ Logs show "Running database migrations" then operational messages
- ✅ External IP accessible for other services
