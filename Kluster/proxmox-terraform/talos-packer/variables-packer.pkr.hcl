variable "proxmox_url" { default = "https://192.168.1.129:8006:8006/api2/json" }
variable "proxmox_user" { default = "root@pam!packer" }
variable "proxmox_token" { default = "" }
variable "proxmox_node" { default = "KHABC" }



variable "vm_id"     { default = 9700 }
variable "vm_name"   { default = "talos-v1.11-template" }
variable "memory"    { default = 2048 }
variable "cores"     { default = 2 }