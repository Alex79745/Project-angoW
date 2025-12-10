variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.1.129:8006/api2/json"
}

variable "proxmox_token_id" {
  description = "Proxmox API token id (format: user@pam!token)"
  type        = string
  default     = "terraform@pam!token"
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret in case the need comes"
  type        = string
  default     = "corresponding secret"
}

variable "target_node" {
  description = "Proxmox node to spawn VMs on"
  type        = string
  default     = "HKABC"
}
