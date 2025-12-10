#!/usr/bin/env bash
set -euo pipefail

echo "=== OMNI ON-PREM INSTALL SCRIPT (v1.3.4 + NGINX) ==="

# ------------------------------
# CONFIGURATION
# ------------------------------
OMNI_VERSION="v1.3.4"
OMNI_DOMAIN_NAME="omni-web.omnilocalwebxaaas.dpdns.org"
OMNI_ACCOUNT_UUID=$(uuidgen || cat /proc/sys/kernel/random/uuid)
OMNI_DIR="/opt/omni"
CERT_DIR="${OMNI_DIR}/certs"
ETCD_DIR="${OMNI_DIR}/etcd"
GPG_KEY_FILE="${OMNI_DIR}/omni.asc"
INITIAL_USER_EMAILS="admin@lab.local,eligiblebachelor49@gmail.com,felipesergiosouza@gmail.com"
EVENT_SINK_PORT="8091"
OMNI_WG_IP=10.10.1.100
OMNI_ADMIN_EMAIL=eligiblebachelor49@gmail.com
export OMNI_AUTH0_CALLBACK_URL=https://omni-web.omnilocalwebxaaas.dpdns.org:443/oidc/callback


# Bind internal ports for Omni
BIND_ADDR="127.0.0.1:8080"
MACHINE_API_BIND_ADDR="127.0.0.1:8090"
K8S_PROXY_BIND_ADDR="127.0.0.1:8100"

ADVERTISED_API_URL="https://${OMNI_DOMAIN_NAME}"
ADVERTISED_K8S_PROXY_URL="https://${OMNI_DOMAIN_NAME}:6444"
SIDEROLINK_ADVERTISED_API_URL="https://${OMNI_DOMAIN_NAME}:8086"
SIDEROLINK_WIREGUARD_ADVERTISED_ADDR="10.0.0.1:51820"
NAME="omni"
ETCD_VOLUME_PATH="${ETCD_DIR}"
TLS_CERT="${CERT_DIR}/origin.pem"
TLS_KEY="${CERT_DIR}/origin.key"

# ------------------------------
# DEPENDENCIES
# ------------------------------
echo "[1/9] Installing dependencies..."
sudo apt update -y
sudo apt install -y curl gnupg ca-certificates lsb-release libnss3-tools openssl uuid-runtime nginx

# ------------------------------
# DOCKER + COMPOSE
# ------------------------------
echo "[2/9] Installing Docker and Docker Compose..."
curl -fsSL https://get.docker.com | sh
sudo apt-get install -y docker-compose
sudo usermod -aG docker $USER

# ------------------------------
# CREATE DIRECTORIES
# ------------------------------
echo "[3/9] Creating directories..."
sudo mkdir -p "${CERT_DIR}" "${ETCD_DIR}" "${OMNI_DIR}/_out/etcd"
sudo chown -R $USER:$USER "${OMNI_DIR}"
chmod 700 "${ETCD_DIR}" "${OMNI_DIR}/_out/etcd"

# ------------------------------
# TLS WITH MKCERT
# ------------------------------
echo "[4/9] Creating TLS certificates..."
curl -sSL "https://dl.filippo.io/mkcert/latest?for=linux/amd64" -o /tmp/mkcert
chmod +x /tmp/mkcert
sudo mv /tmp/mkcert /usr/local/bin/mkcert

mkcert -install
mkcert -cert-file "${TLS_CERT}" -key-file "${TLS_KEY}" "${OMNI_DOMAIN_NAME}"
chmod 600 "${TLS_KEY}"

# ------------------------------
# GPG KEY FOR ETCD
# ------------------------------
echo "[5/9] Generating GPG key for ETCD..."
rm -f "$GPG_KEY_FILE"

gpg --batch --gen-key <<EOF
%echo Generating ETCD key
Key-Type: RSA
Key-Length: 4096
Name-Real: Omni etcd key
Name-Email: omni@lab.local
Expire-Date: 0
%no-protection
%commit
%echo done
EOF

GPG_FPR=$(gpg --list-secret-keys --with-colons | awk -F: '$1=="sec"{print $5; exit}')
gpg --export-secret-key --armor "$GPG_FPR" > "$GPG_KEY_FILE"
chmod 600 "$GPG_KEY_FILE"
echo "GPG saved at: $GPG_KEY_FILE"

# ------------------------------
# CREATE DOCKER-COMPOSE
# ------------------------------
echo "[6/9] Creating docker-compose.yml..."
cat > "${OMNI_DIR}/docker-compose.yml" <<EOF
version: "3.9"

services:
  omni:
    container_name: omni
    image: "ghcr.io/siderolabs/omni:${OMNI_VERSION}"
    devices:
      - /dev/net/tun
    volumes:
      - ${ETCD_VOLUME_PATH}:/_out/etcd
      - ${GPG_KEY_FILE}:/omni.asc
      - ${TLS_CERT}:/tls.crt
      - ${TLS_KEY}:/tls.key
    network_mode: "host"
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
    command: >
      --account-id=${OMNI_ACCOUNT_UUID}
      --name=${NAME}
      --cert=/tls.crt
      --key=/tls.key
      --siderolink-api-cert=/tls.crt \
      --siderolink-api-key=/tls.key \
      --machine-api-cert=/tls.crt
      --machine-api-key=/tls.key
      --private-key-source='file:///omni.asc'
      --event-sink-port=${EVENT_SINK_PORT}
      --bind-addr=${BIND_ADDR}
      --machine-api-bind-addr=${MACHINE_API_BIND_ADDR}
      --k8s-proxy-bind-addr=${K8S_PROXY_BIND_ADDR}
      --advertised-api-url=${ADVERTISED_API_URL}
      --advertised-kubernetes-proxy-url=${ADVERTISED_K8S_PROXY_URL}
      --siderolink-api-advertised-url=${SIDEROLINK_ADVERTISED_API_URL}
      --siderolink-wireguard-advertised-addr=${SIDEROLINK_WIREGUARD_ADVERTISED_ADDR}
      --initial-users=${INITIAL_USER_EMAILS}
      --auth-auth0-enabled=true
      --auth-auth0-domain=dev-btis8ydrur6r52xl.us.auth0.com
      --auth-auth0-client-id=odSNUNWEkGtUuEIulsGqbGuABHEk70VU
EOF

# ------------------------------
# START OMNI
# ------------------------------
echo "[7/9] Starting Omni with Docker Compose..."
cd "${OMNI_DIR}"
sudo docker compose down || true
sudo docker compose pull
sudo docker compose up -d

# ------------------------------
# CONFIGURE NGINX
# ------------------------------
echo "[8/9] Configuring Nginx as reverse proxy..."
sudo tee /etc/nginx/sites-available/omni.conf > /dev/null <<'EOF'

# -----------------------------
# HTTP → HTTPS redirect
# -----------------------------
server {
    listen 80;
    server_name ${OMNI_DOMAIN_NAME};

    location / {
        return 301 https://$host$request_uri;
    }
}

# -----------------------------
# Omni main API
# -----------------------------
server {
    listen 443 ssl http2;
    server_name ${OMNI_DOMAIN_NAME};
    ssl_certificate /opt/omni/certs/origin.pem;
    ssl_certificate_key /opt/omni/certs/origin.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # handle websocket upgrade
    set $connection_upgrade "";
    if ($http_upgrade != "") {
        set $connection_upgrade $http_upgrade;
    }

    # detect gRPC
    set $is_grpc 0;
    if ($http_content_type = "application/grpc") {
        set $is_grpc 1;
    }

    location / {
        error_page 418 = @grpc;
        error_page 419 = @http;

        if ($is_grpc) { return 418; }
        return 419;
    }

    location @grpc {
        grpc_pass grpc://127.0.0.1:8080;
        grpc_read_timeout 1h;
        grpc_send_timeout 1h;
    }

    location @http {
        proxy_pass https://127.0.0.1:8080;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}

# -----------------------------
# SideroLink / Machine API
# -----------------------------
server {
    listen 443 ssl http2;
    server_name api.${OMNI_DOMAIN_NAME};

    ssl_certificate /opt/omni/certs/origin.pem;
    ssl_certificate_key /opt/omni/certs/origin.key;



    set $connection_upgrade "";
    if ($http_upgrade != "") {
        set $connection_upgrade $http_upgrade;
    }

    location / {
        grpc_pass grpc://127.0.0.1:8090;
        grpc_read_timeout 1h;
        grpc_send_timeout 1h;
    }
}

# -----------------------------
# Kube API
# -----------------------------
server {
    listen 443 ssl http2;
    server_name kube.${OMNI_DOMAIN_NAME};


    ssl_certificate /opt/omni/certs/origin.pem;
    ssl_certificate_key /opt/omni/certs/origin.key;


    set $connection_upgrade "";
    if ($http_upgrade != "") {
        set $connection_upgrade $http_upgrade;
    }

    location / {
        proxy_pass http://127.0.0.1:8100;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}


EOF

sudo ln -sf /etc/nginx/sites-available/omni.conf /etc/nginx/sites-enabled/omni.conf
sudo nginx -t
sudo systemctl restart nginx

# ------------------------------
# CONFIGURE FIREWALL (UFW)
# ------------------------------
echo "[8.1/9] Allowing HTTP/HTTPS through firewall..."
#sudo apt install -y ufw
#sudo ufw allow 80/tcp
#sudo ufw allow 443/tcp
#sudo ufw reload || true

# ------------------------------
# FINISH
# ------------------------------
echo "[9/9] ✅ OMNI + NGINX configured!"
echo "🔗 URL: https://${OMNI_DOMAIN_NAME} (add to hosts if accessing from another PC)"
echo "🆔 Account UUID: ${OMNI_ACCOUNT_UUID}"
echo "⚠️ Logs Omni: sudo docker-compose logs omni --follow"
