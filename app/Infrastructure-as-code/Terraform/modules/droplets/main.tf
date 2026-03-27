
resource "digitalocean_droplet" "this" {
count = var.count
name = "${var.name_prefix}-${count.index + 1}"
region = var.region
size = var.size
image = var.image
ssh_keys = [var.ssh_fingerprint]
vpc_uuid = var.vpc_uuid
backups = true
tags = ["${var.name_prefix}", "${replace(var.name_prefix, "-", "")}", var.name_prefix, var.name_prefix]


user_data = templatefile("${path.module}/cloud-init-app.tpl", {
repo = var.repo,
branch = var.branch
})
}


# Tag the droplets with a common tag the LB can use
resource "digitalocean_droplet_tag" "tag_attach" {
count = var.count
droplet_id = digitalocean_droplet.this[count.index].id
tag_id = digitalocean_tag.web_tag.id
}


output "droplet_ips" {
value = [for d in digitalocean_droplet.this : d.ipv4_address]
}
