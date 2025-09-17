# Cognee GCP VM Setup

Deploy Cognee to a fresh GCP VM with one command.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Hack-Projects-n-Teams/cognee-to-gcp-vm/master/quick-install.sh | bash
```

**What it does:**
- Installs Docker + dependencies
- Configures firewall (ports 8000, 80, 443)
- Prompts for Qdrant credentials
- Starts Cognee services
- Tests health endpoint

## Manual Install

```bash
git clone https://github.com/Hack-Projects-n-Teams/cognee-to-gcp-vm.git
cd cognee-to-gcp-vm
chmod +x install.sh
./install.sh
```

## Post-Install Commands

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart && sleep 10 && curl http://localhost:8000/health

# Stop services
docker-compose down
```

## Environment Variables

The installer will prompt for:
- `QDRANT_URL`: Your Qdrant cluster URL
- `QDRANT_API_KEY`: Your Qdrant API key

## Access

- Local: `http://localhost:8000`
- External: `http://YOUR_VM_PUBLIC_IP:8000`
- Health check: `curl http://localhost:8000/health`

## Troubleshooting

If services don't start:
```bash
# Check logs
docker-compose logs

# Restart with verbose output
docker-compose up --build

# Check ports
sudo netstat -tlnp | grep 8000
```