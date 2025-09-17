# NetworkMind Cognee VM Setup

This directory contains reusable scripts and configurations for deploying Cognee on Google Cloud Platform (GCP).

## Quick Start

### Zero-Cost Setup (e2-micro)
```bash
# 1. Create VM
gcloud compute instances create networkmind-cognee \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-project=ubuntu-os-cloud \
  --image-family=ubuntu-2204-lts \
  --boot-disk-size=30GB \
  --firewall-rules=http-server,https-server \
  --tags=cognee

# 2. SSH into VM
gcloud compute ssh networkmind-cognee

# 3. Install Docker
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# 4. Run Cognee
sudo docker run -d \
  --name cognee \
  --restart unless-stopped \
  -p 8000:8000 \
  -e VECTOR_DB_PROVIDER=qdrant \
  -e VECTOR_DB_URL="${QDRANT_URL}" \
  -e VECTOR_DB_KEY="${QDRANT_API_KEY}" \
  -v cognee_data:/app/data \
  cognics/cognee:latest

# 5. Test
curl http://localhost:8000/health
```

### Upgraded Setup (e2-small)

Replace `e2-micro` with `e2-small` in the create command for better performance. Costs $5.13/month.

## Oracle Cloud ARM64 Alternative

```bash
# AMD64 (Intel)
docker run -d --name cognee autonomedge/cognee:latest-amd64

# ARM64 (Apple Silicon/Azure)
docker run -d --name cognee autonomedge/cognee:latest-arm64
```

## Environment Configuration

Update the `.env` file in your project root with the actual URLs:

```env
COGNEE_BASE_URL=http://VM_EXTERNAL_IP:8000
VECTOR_DB_URL=your-qdrant-url
VECTOR_DB_KEY=your-qdrant-api-key
```

## Monitoring Commands

```bash
# View logs
sudo docker logs cognee

# Check if running
sudo docker ps -a

# Restart if needed
sudo docker restart cognee
```

## Volume Management

Cognee data is persisted in Docker volume `cognee_data`:

```bash
# List volumes
sudo docker volume ls

# Inspect volume
sudo docker volume inspect cognee_data
```

## Migration

To migrate to production:

1. Take VM snapshot for backup
2. Change machine type: `gcloud compute instances stop/start --machine-type=e2-small`
3. Update DNS/load balancer
4. Monitor performance

## Cost Optimization

- **e2-micro (free)**: Perfect for testing, single user
- **e2-small ($5/month)**: Multiple users, reliable performance
- **Auto-scaled VMs ($0.xx/hour)**: High traffic scenarios

Total estimated cost for MVP: $5.13/month
