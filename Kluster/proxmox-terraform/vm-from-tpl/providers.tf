terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.51.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.1.129:8006/api2/json"
  username = "root@pam"
  password = "928195424"
  insecure = true
}
