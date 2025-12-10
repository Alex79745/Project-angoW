variable "proxmox_api_url" { default = "https://PROXMOX:8006/api2/json" }
variable "proxmox_token_id" { default = "terraform@pam!token" }
variable "proxmox_token_secret" { default = "TOKEN_SECRET" }
variable "target_node" { default = "pve-node1" }