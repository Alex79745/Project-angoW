#!/bin/bash
# setup_docker_viewers.sh
# Purpose: Create restricted Docker viewer environment for multiple users

set -e

# Users to grant restricted docker access
USERS=("bidala" "demo_user" "alice" "bob")   # <-- add all your users here
GROUP_NAME="docker-viewer"
WRAPPER_PATH="/usr/local/bin/docker-viewer"

echo "🔧 Creating docker viewer group..."
sudo groupadd -f "$GROUP_NAME"

# Create wrapper once
echo "🧰 Creating Docker viewer wrapper at $WRAPPER_PATH..."
sudo tee "$WRAPPER_PATH" > /dev/null <<'EOF'
#!/bin/bash
# Docker viewer wrapper — safe limited commands

case "$1" in
  ps|-ps|--ps)
    docker -H tcp://127.0.0.1:2375 ps "${@:2}"
    ;;
  logs)
    docker -H tcp://127.0.0.1:2375 logs "${@:2}"
    ;;
  info)
    docker -H tcp://127.0.0.1:2375 info
    ;;
  *)
    echo "Error: You can only run 'docker ps', 'docker ps -a', or 'docker logs <container>'."
    exit 1
    ;;
esac
EOF

sudo chmod +x "$WRAPPER_PATH"
sudo chown root:$GROUP_NAME "$WRAPPER_PATH"
sudo chmod 750 "$WRAPPER_PATH"

# Loop through users
for USER_NAME in "${USERS[@]}"; do
  echo "👤 Configuring user $USER_NAME..."

  # Add user to group
  sudo usermod -aG "$GROUP_NAME" "$USER_NAME" || true

  # Add alias
  ALIAS_FILE="/home/${USER_NAME}/.bash_aliases"
  sudo tee "$ALIAS_FILE" > /dev/null <<EOF
alias docker="$WRAPPER_PATH"
EOF
  sudo chown "$USER_NAME:$USER_NAME" "$ALIAS_FILE"

  # Ensure home dir exists
  if [ ! -d "/home/$USER_NAME" ]; then
    sudo mkdir -p "/home/$USER_NAME"
    sudo chown "$USER_NAME:$USER_NAME" "/home/$USER_NAME"
  fi

done

echo "📦 Starting docker socket proxy via Docker Compose..."
sudo docker compose up -d docker-socket-proxy

echo "✅ Docker viewer environment setup complete for users: ${USERS[*]}"
echo "➡️ Users must log out and log back in to apply group membership and aliases."
s