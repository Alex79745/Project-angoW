#cloud-config
runcmd:
  # ===== System updates and required packages =====
  - apt-get update && apt-get install -y git curl sudo

  # ===== Docker & Compose (if needed) =====
  - curl -fsSL https://get.docker.com | sh
  - apt-get install -y docker-compose

  # ===== Application deployment =====
  - mkdir -p /srv/app
  - cd /srv/app
  - |
    if [ ! -d "app_repo" ]; then
      git clone --depth 1 "${repo}" app_repo
    else
      cd app_repo && git fetch && git checkout ${branch} && git reset --hard origin/${branch}
    fi
  - cd app_repo/app || cd app_repo
  - docker compose pull || true
  - echo "DB_URI=${db_uri}" >> /etc/environment
  - echo "DB_HOST=${db_host}" >> /etc/environment
  - export DB_URI=${db_uri}
  - export DB_HOST=${db_host}
  - docker compose up -d --remove-orphans

  # ===== Create groups =====
  - getent group devops-cloud || groupadd devops-cloud
  - getent group developer || groupadd developer

  # ===== Create users =====
  - id -u architech &>/dev/null || useradd -m -s /bin/bash -G devops-cloud architech
  - id -u coder &>/dev/null || useradd -m -s /bin/bash -G developer coder

  # ===== Setup home directories and permissions =====
  - mkdir -p /home/coder/.ssh
  - chmod 700 /home/coder/.ssh
  - chown coder:developer /home/coder/.ssh
  - mkdir -p /home/architech/.ssh
  - chmod 700 /home/architech/.ssh
  - chown architech:devops-cloud /home/architech/.ssh

  # ===== Optional sudo =====
  - echo "architech ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/architech
  - echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder

  # ===== Tailscale SSH =====
  - curl -fsSL https://tailscale.com/install.sh | sh
  - tailscale up --authkey=${TAILSCALE_AUTHKEY} --ssh --advertise-tags=${TAILSCALE_TAG}

  # ===== Ensure SSH service is running =====
  - systemctl restart ssh
