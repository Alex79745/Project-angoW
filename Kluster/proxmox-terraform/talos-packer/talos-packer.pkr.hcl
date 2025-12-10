# packer {
#   required_plugins {
#     proxmox = {
#       source  = "github.com/hashicorp/proxmox"
#       version = "~> 1.2"
#     }
#   }
# }

# variable "proxmox_url" { default = "https:192.168.1.129:8006///api2/json" }
# variable "proxmox_user" { default = "root@pam" }
# variable "proxmox_password" { default = "928195424" }                                
# variable "proxmox_node" { default = "KHABC" }


# variable "vm_id"     { default = 9700 }
# variable "vm_name"   { default = "talos-v1.11-template" }
# variable "memory"    { default = 2048 }
# variable "cores"     { default = 2 }

# source "proxmox-iso" "talos" {
#   proxmox_url      = var.proxmox_url
#   username         = var.proxmox_user
#   password         = var.proxmox_password
#   node             = var.proxmox_node
#   vm_id            = var.vm_id
#   vm_name          = var.vm_name
#   memory           = var.memory
#   cores            = var.cores

#   boot_iso {
#     type       = "ide"
#     iso_file   = "local:iso/metal-amd64.iso"
#     unmount    = true
#   }

#   disks {
#     type         = "scsi"
#     storage_pool = "local-lvm"
#     disk_size    = "20G"
#     format       = "qcow2"
#   }


#  network_adapters {
#   model  = "virtio"
#   bridge = "vmbr0"
# }
#   qemu_agent       = false
#   cloud_init       = true           # attach cloud-init drive #maybe later with ip
#   cloud_init_storage_pool = "local"
# }

# build {
#   sources = ["source.proxmox-iso.talos"]
# }
#----------------------------------------------------------------------------------------------------------------


#----------------------------------------------------------------------------------------------------------------

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url"      { default = "https://192.168.1.129:8006/api2/json" }
variable "proxmox_user"     { default = "root@pam" }
variable "proxmox_password" { default = "928195424" }
variable "proxmox_node"     { default = "KHABC" }

variable "vm_id"   { default = 9700 }
variable "vm_name" { default = "talos-v1.11-template" }

source "proxmox-iso" "talos" {
  #url      = var.proxmox_url
  username = var.proxmox_user
  password = var.proxmox_password
  node     = var.proxmox_node
  vm_id    = var.vm_id
  vm_name  = var.vm_name

  iso_storage_pool = "local"
  iso_file         = "metal-amd64.iso"

  #storage_pool = "local-lvm"
  #disk_size    = "20G"

  cores  = 2
  memory = 2048

  ssh_username = "" # required but unused
  ssh_password = "" # required but unused
}


 build {
   sources = ["source.proxmox-iso.talos"]
}