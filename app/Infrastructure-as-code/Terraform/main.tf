

resource "digitalocean_vpc" "main" {
name = "${var.project_name}-vpc"
region = var.region
}


# Tag used to select droplets for LB
resource "digitalocean_tag" "web_tag" {
name = "${var.project_name}-web"
}


# Managed Database
module "managed_db" {
source = "./modules/managed_db"
db_name = "${var.project_name}-db"
region = var.region
size = var.managed_db_size
}


# Create two droplets for app
module "app_droplets" {
source = "./modules/droplets"
count = 2
name_prefix = "${var.project_name}-web"
region = var.region
size = var.droplet_size
image = var.droplet_image
ssh_fingerprint = var.ssh_fingerprint
vpc_uuid = digitalocean_vpc.main.id
repo = var.app_repo
branch = var.app_repo_branch
}


# Load balancer
resource "digitalocean_loadbalancer" "app_lb" {
name = "${var.project_name}-lb"
region = var.region


forwarding_rule {
entry_protocol = "http"
entry_port = 80
target_protocol = "http"
target_port = 80
}


health_check {
protocol = "http"
port = 80
path = "/health"
}


droplet_tag = digitalocean_tag.web_tag.name
}


output "loadbalancer_ip" {
value = digitalocean_loadbalancer.app_lb.ip
}


output "droplet_ips" {
value = module.app_droplets.droplet_ips
}


output "managed_db_uri" {
value = module.managed_db.uri
}