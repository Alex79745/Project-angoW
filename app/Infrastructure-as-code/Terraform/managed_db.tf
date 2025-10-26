# infra/terraform/managed_db.tf
resource "digitalocean_database_cluster" "mysql" {
  name       = "hotel-db-${terraform.workspace}"
  engine     = "mysql"
  version    = "8"
  region     = var.region
  size       = var.managed_db_size        # e.g. db-s-2vcpu-4gb
  node_count = 2                          # managed HA with replica
}

output "managed_db_uri" { value = digitalocean_database_cluster.mysql[0].uri }
