variable "region" { type = string, default = "fra1" }
variable "droplet_size_app" { type = string, default = "s-2vcpu-2gb" }
variable "ssh_fingerprint" { type = string }
variable "managed_db_size" { type = string, default = "db-s-1vcpu-1gb" }


variable "db_name" { type = string }
variable "region" { type = string }
variable "size" { type = string }



variable "do_token" {}

variable "region" {
description = "DigitalOcean region"
type = string
default = "fra1"
}


variable "droplet_size" {
description = "Droplet size slug for app droplets"
type = string
default = "s-2vcpu-2gb"
}


variable "droplet_image" {
description = "Droplet image slug (Docker preinstalled recommended)"
type = string
default = "docker-20-04"
}


variable "project_name" {
description = "Project prefix/name"
type = string
default = "hotel-app"
}


variable "app_repo" {
description = "Git repo URL containing your app and docker-compose.yml (public or accessible)"
type = string
default = "https://github.com/YOUR_ORG/YOUR_REPO.git"
}


variable "app_repo_branch" {
description = "Branch to checkout on droplets"
type = string
default = "main"
}


variable "managed_db_size" {
description = "Managed DB size slug"
type = string
default = "db-s-1vcpu-1gb"
}


