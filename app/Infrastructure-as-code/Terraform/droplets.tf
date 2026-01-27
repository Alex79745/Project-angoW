# infra/terraform/droplets.tf
resource "digitalocean_droplet" "app" {
  count      = 2                                   # create 2 droplets for HA
  name       = "hotel-app-${terraform.workspace}-${count.index + 1}"
  region     = var.region
  size       = var.droplet_size_app
  image      = "docker-20-04"                      # droplets with Docker preinstalled
  ssh_keys   = [var.ssh_fingerprint]
  backups    = true                                # enable automatic DO backups (no scripts)
  tags       = ["hotel-app", terraform.workspace]

  user_data  = file("${path.module}/cloud-init-app.sh") # optional bootstrap script
}

output "app_ips" {
  value = digitalocean_droplet.app[*].ipv4_address
}
