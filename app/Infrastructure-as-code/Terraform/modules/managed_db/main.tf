
resource "digitalocean_database_cluster" "db" {
name = var.db_name
engine = "mysql"
version = "8"
region = var.region
size = var.size
node_count = 2
}


output "uri" {
value = digitalocean_database_cluster.db.uri
}
output "managed_db_uri" {
  value = module.managed_db.uri
}