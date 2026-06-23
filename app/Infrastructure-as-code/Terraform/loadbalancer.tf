# infra/terraform/loadbalancer.tf
resource "digitalocean_loadbalancer" "app_lb" {
  name   = "hotel-lb-${terraform.workspace}"
  region = var.region

  forwarding_rule {
    entry_protocol  = "https"
    entry_port      = 443
    target_protocol = "http"
    target_port     = 80
  }

  health_check {
    protocol = "http"
    port     = 80
    path     = "/health"
    check_interval_seconds = 10
    response_timeout_seconds = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
  }

  droplet_ids = digitalocean_droplet.app[*].id

  # TLS: you can later attach a certificate via UI or use Let's Encrypt via nginx & CA
}
output "loadbalancer_ip" { value = digitalocean_loadbalancer.app_lb.ip }
