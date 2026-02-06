# 🌐 Automated Home Lab Deployment (Pi-hole & n8n)

This repository defines and manages my personal home lab services using **Infrastructure as Code (IaC) principles** via Docker Compose and a small amount of Shell scripting. The project establishes a core home infrastructure platform for network-wide ad blocking and custom automation workflows.

This is a demonstration of skills in containerization, configuration management, and operational scripting for a robust, persistent home server environment.

## ✨ Technologies Demonstrated

| Category | Technology | Skill Highlighted |
| :--- | :--- | :--- |
| **Containerization** | Docker / Docker Compose | Multi-container application deployment and networking. |
| **IaC & Config Mgmt** | `docker-compose.yml` | Declarative infrastructure definition, version control, and volume persistence. |
| **Scripting & Ops** | Bash (`manage.sh`) | Automating common operational tasks (start, stop, update, logging) with proper secret handling. |
| **Services** | Pi-hole / dnsmasq | Network-level DNS filtering, service configuration, and container capabilities (`NET_ADMIN`). |
| **Services** | n8n | Workflow automation agent and third-party API integration. |
| **Security** | Docker Port Binding | Implementing the **Principle of Least Privilege** by isolating network access. |

## 💾 Host Environment Specification

| Component | Detail | Notes |
| :--- | :--- | :--- |
| **Hardware** | **Raspberry Pi 3 Model B** | Multi-core ARM-based processor; a constrained, resource-efficient deployment platform. |
| **Operating System** | **Raspberry Pi OS (Based on Debian 13 "Trixie")** | The entire solution is validated and running on the latest stable Debian environment. |
| **RAM** | 1GB LPDDR2 | The primary resource constraint, highlighting the use of the `EXECUTIONS_PROCESS=main` variable for efficient memory utilization by n8n. |

## 🏗️ Deployment Architecture

The entire stack is defined in one `docker-compose.yml` file and runs on a single host.

| Service | Container Image | Function | Access Point |
| :--- | :--- | :--- | :--- |
| **Pi-hole** | `pihole/pihole:latest` | DNS-based ad blocking and network DHCP services. | `http://[Pi_IP_Address]/admin` (Port 80) |
| **n8n** | `n8nio/n8n` | Workflow automation agent for scheduled tasks (e.g., job search monitoring). | `http://localhost:5678` (Via SSH Tunnel) |

## 📝 Configuration Files (For Commit)

### `docker-compose.yml`
```yaml
version: "3.7"

services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    environment:
      TZ: ${TZ:-America/Toronto}
      WEBPASSWORD: ${PIHOLE_PASSWORD}
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    cap_add:
      - NET_ADMIN
    restart: unless-stopped

  n8n:
    image: n8nio/n8n
    container_name: n8n
    # Port is bound to 127.0.0.1 for security, requiring an SSH tunnel to access.
    ports:
      - "127.0.0.1:5678:5678"
    environment:
      TZ: ${TZ:-America/Toronto}
      DB_TYPE: sqlite
      # Uses the main execution process to conserve memory on the 1GB Pi.
      EXECUTIONS_PROCESS: main 
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped

volumes:
  n8n_data:
```

### `manage.sh` (Operational Script)
```bash
#!/bin/bash
# manage.sh

# A simple script to manage the home lab Docker Compose stack
# Demonstrates operational scripting for service lifecycle management.

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Check for required variables
if [ -z "$PIHOLE_PASSWORD" ]; then
  echo "Error: PIHOLE_PASSWORD is not set in the .env file."
  exit 1
fi

case "$1" in
  start)
    echo "Starting home lab services..."
    docker compose up -d
    ;;
  stop)
    echo "Stopping home lab services..."
    docker compose down
    ;;
  logs)
    echo "Tailing logs for all services..."
    docker compose logs -f
    ;;
  update)
    echo "Updating all service images (pull and recreate)..."
    docker compose pull
    docker compose up -d --force-recreate
    echo "Update complete."
    ;;
  *)
    echo "Usage: $0 {start|stop|logs|update}"
    exit 1
    ;;
esac

exit 0
```

## 🚀 Quick Start Guide

### 1. Setup & Secrets Management

```bash
# Clone the repository
git clone [YOUR_GITHUB_REPO_URL]
cd [YOUR_REPO_NAME]

# Create the .env file from the example
cp .env.example .env

# --- CRITICAL: Edit the .env file and set a strong PIHOLE_PASSWORD and your TZ ---
nano .env 
```
***Note:** The `.env` file is in your `.gitignore` and must never be committed to the repository.*

### 2. Deployment

Make the script executable and deploy the stack:

```bash
chmod +x manage.sh
./manage.sh start
```

### 3. Access n8n Securely (SSH Tunnel)

To access the n8n Web UI from your computer, create an **SSH Tunnel**. This is the secure method, as the service is not exposed to your LAN.

```bash
# Keep this terminal window open while working in n8n
# This forwards the remote port 5678 to your local port 5678
ssh -L 5678:localhost:5678 pi@[your_pi_ip_address]
```

Then, open your browser and go to: `http://localhost:5678`
