packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.2.0"
    }
  }
}

variable "proxmox_url" { default = "https://PROXMOX:8006/api2/json" }
variable "proxmox_user" { default = "root@pam" }
variable "proxmox_password" { default = "CHANGE_ME" }
variable "proxmox_node" { default = "HKABC" }
variable "iso_file" { default = "local:iso/archlinux-x86_64.iso" }
variable "talos_image_url" { default = "https://factory.talos.dev/image/amd64/raw/latest.raw.xz" }
variable "vm_id" { default = 9700 }
variable "vm_name" { default = "talos-arch-helper-template" }
variable "memory" { default = 2048 }
variable "cores" { default = 2 }

source "proxmox-iso" "talos_arch_helper" {
  proxmox_url = var.proxmox_url
  username    = var.proxmox_user
  password    = var.proxmox_password
  node        = var.proxmox_node

  vm_id   = var.vm_id
  vm_name = var.vm_name

  boot_iso {
    type     = "ide"
    iso_file = var.iso_file
    unmount  = true
  }

  disks {
    type         = "scsi"
    storage_pool = "local-lvm"
    disk_size    = "20G"
    format       = "raw"
  }

  cores  = var.cores
  memory = var.memory

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # The Arch helper will be configured via boot_command to set a temporary root password and network
  ssh_username = "root"
  ssh_password = "packer"            # created by the boot_command
  ssh_timeout  = "20m"

  # convert to template when finished
  template_name        = var.vm_name
  template_description = "Talos (preloaded) template built via Arch helper + Packer"
  convert_to_template  = true

  # adjust so Packer waits for boot
  boot_wait = "10s"

  # Boot command: press Enter, set root password, configure static IP (or DHCP if you prefer)
  # NOTE: you must adapt device name (ens18, enp0s3...) and timing to your environment.
  boot_command = [
    "<enter><wait10s>",
    "root<enter>",
    "passwd<enter>",
    "packer<enter>",
    "packer<enter>",
    "ip link set dev ens18 up<enter><wait>",
    "dhcpcd -w -t 10 ens18 &<enter><wait2s>",
    "mkdir -p /root/.ssh<enter><wait>",
    "echo 'authorized_key_placeholder' > /root/.ssh/authorized_keys<enter><wait>",
    "sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config || true<enter><wait>",
    "systemctl restart sshd || true<enter><wait>",
    "<wait30s>"
  ]
}

build {
  sources = ["source.proxmox-iso.talos_arch_helper"]

  provisioner "file" {
    source      = "scripts/provision_write_talos.sh"
    destination = "/root/provision_write_talos.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /root/provision_write_talos.sh",
      "/root/provision_write_talos.sh '{{user `talos_image_url`}}'"
    ]
  }
}