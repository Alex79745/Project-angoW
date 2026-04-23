DigitalOcean Production Terraform project (deployable)
# ======================================================
# This project provisions a production-ready DigitalOcean stack:
# - VPC
# - 2 x Droplets (app servers) with Docker & Docker Compose bootstrapped
# - DigitalOcean Load Balancer pointing to both droplets (health checks)
# - DigitalOcean Managed MySQL (HA)
# - Tagging and outputs
#
# HOW TO USE
# 1. Place this directory on your machine.
# 2. Edit terraform/variables.tf or pass -var arguments / tfvars file with your values.
# 3. Ensure your app repo is accessible (public or add SSH deployment key and adjust setup script).
# 4. Run: terraform init && terraform apply -var "do_token=..." -var "ssh_fingerprint=..."
#
# IMPORTANT: Do NOT commit secrets (.tfvars containing tokens) to public repos.


Quick start
# 1. place files in a directory named `terraform/` at root of your repo
# 2. edit variables in variables.tf or create a terraform.tfvars with sensitive values
# e.g. terraform.tfvars:
# do_token = "your_do_token"
# ssh_fingerprint = "your_ssh_key_fingerprint"
# app_repo = "https://github.com/you/your-repo.git"
# 3. terraform init
# 4. terraform apply


http://192.168.56.16:8080/