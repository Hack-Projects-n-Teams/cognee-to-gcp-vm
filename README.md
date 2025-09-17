# Cognee VM Setup

A complete, automated setup for deploying [Cognee](https://github.com/topoteretes/cognee) on any Ubuntu virtual machine. This repo provides everything needed for a one-command installation.

## Features

- 🚀 **One-command setup**: `./install.sh` handles everything automatically
- 🤖 **Interactive configuration**: Prompts for QDrant credentials if needed
- ✅ **Health verification**: Automatic startup and health checks
- 📦 **Complete package**: Docker, docker-compose, monitoring tools
- 🔒 **Security**: Firewall configuration and proper environment handling

## Quick Start

### Self-Install (Recommended)

Perfect for fresh VMs - no manual configuration needed!

1. **Provision a fresh Ubuntu VM** (20.04 LTS or later)
   ```bash
   # Example with Google Cloud (other clouds work too)
   gcloud compute instances create cognee-vm \
     --zone=us-central1-a \
     --machine-type=e2-micro \
     --image-family=ubuntu-2204-lts \
     --boot-disk-size=30GB
   ```

2. **SSH into your VM**
   ```bash
   gcloud compute ssh cognee-vm
   ```

3. **Clone and run**
   ```bash
   git clone <your-github-repo-url>
   cd vm-setup
   chmod +x install.sh
   ./install.sh
   ```
   The script will:
   - Install Docker and dependencies
   - Prompt for QDrant URL and API key
   - Create the environment file
   - Launch Cognee
   - Verify it's working

4. **Done!** Cognee will be running at `http://localhost:8000`

### Manual Setup

If you prefer manual control:

1. **Install dependencies**
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose jq htop curl wget
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your QDrant credentials
   ```

3. **Launch**
   ```bash
   docker-compose up -d
   ```

4. **Verify**
   ```bash
   curl http://localhost:8000/health
   ```

## Prerequisites

- Ubuntu 20.04 LTS or later (tested on 22.04)
- Fresh VM with sudo access (not required but recommended)
- QDrant instance (Cloud or self-hosted)

### QDrant Setup

You'll need a QDrant vector database. Options:

- **QDrant Cloud** (easier): https://cloud.qdrant.io
- **Self-hosted**: Docker setup available at https://qdrant.tech/documentation/quick-start/

## Environment Configuration

Copy `.env.example` to `.env` and configure:

```env
QDRANT_URL=https://your-qdrant-instance-url:6333
QDRANT_API_KEY=your-qdrant-api-key
```

The install script will prompt for these if the file doesn't exist.

## Cloud Provider Examples

### Google Cloud Platform (GCP)
```bash
gcloud compute instances create cognee-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --boot-disk-size=30GB \
  --tags=cognee
```

### AWS EC2
```bash
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.micro \
  --key-name your-key \
  --security-groups cognee-sg
```

### DigitalOcean
Use the Ubuntu droplet, then run the install script.

## Operations

Once running, useful commands:

```bash
# View logs
docker-compose logs -f

# Restart Cognee
docker-compose restart

# Stop everything
docker-compose down

# Check health
curl http://localhost:8000/health
```

## Volume Management

Data persists in Docker volume `cognee_data`:

```bash
# List volumes
docker volume ls

# Inspect
docker volume inspect cognee_data

# Backup (optional)
docker run --rm -v cognee_data:/data -v $(pwd):/backup alpine tar czf /backup/cognee-backup.tar.gz -C /data .
```

## Architecture

- **Cognee**: Main application container (port 8000)
- **QDrant**: External vector database
- **Docker Compose**: Orchestration
- **Persistent Volumes**: Data storage

## Cost Optimization

Recommended instance types:
- **Free tier VMs**: Perfect for testing (e2-micro, t3.micro)
- **Small production**: e2-small ($5/month), t3.small ($9/month)
- **Scale**: Auto-scaling groups for high traffic

## Troubleshooting

### Common Issues

**1. Docker permission denied**
```bash
sudo usermod -aG docker $USER
# Logout and login again
```

**2. Port 8000 already in use**
```bash
sudo netstat -tulpn | grep :8000
# Or change port in docker-compose.yml
```

**3. Health check fails**
```bash
docker-compose logs cognee
# Check QDrant connectivity and credentials
```

**4. Firewall issues**
```bash
sudo ufw status
sudo ufw allow 8000/tcp
```

### Support

- [Cognee Documentation](https://cognics.github.io/cognee/)
- [QDrant Documentation](https://qdrant.tech/documentation/)
- [Docker Troubleshooting](https://docs.docker.com/engine/troubleshoot/)
