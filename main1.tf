terraform {
  required_version = ">= 1.4"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.51.0"
    }
  }
}

# ===== Inputs =====
variable "node_name"     { type = string }
variable "vm_id"         { type = number }
variable "name"          { type = string }
variable "template_vmid" { type = number }
variable "datastore_id"  { type = string }
variable "disk_size_gb"  { type = number }
variable "cpu_cores"     { type = number }
variable "cpu_sockets"   { type = number }
variable "cpu_type"      { type = string }
variable "memory_mb"     { type = number }
variable "bridge"        { type = string }

# Cloud-Init (hostname + rede)
variable "talos_hostname"  { type = string }
variable "talos_ipv4_cidr" { type = string } # ex.: "10.19.10.82/24"
variable "talos_ipv4_gw"   { type = string } # ex.: "10.19.143.1"

# Acesso ao host Proxmox para o check/reboot
variable "proxmox_host" {
  type        = string
  description = "Hostname ou IP do nó Proxmox"
  default     = "10.19.143.21"
}
variable "proxmox_username" {
  type        = string
  description = "Utilizador PAM para SSH no host Proxmox (ex.: root@pam)"
}
variable "proxmox_password" {
  type        = string
  sensitive   = true
  description = "Password do utilizador PAM para SSH (usada por sshpass)"
}

# ===== Clone VM com Cloud-Init IPv4 (sem snippet) =====
resource "proxmox_virtual_environment_vm" "talos_clone" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id
  started   = true

  bios          = "seabios"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  tablet_device = true
  acpi          = true

  agent {
    enabled = true
    timeout = "15m"
    trim    = false
  }

  cpu {
    sockets = var.cpu_sockets
    cores   = var.cpu_cores
    type    = var.cpu_type
    units   = 1024
    numa    = false
  }

  memory { dedicated = var.memory_mb }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
    cache        = "none"
    aio          = "io_uring"
    iothread     = true
    backup       = true
    replicate    = true
    discard      = "ignore"
  }

  network_device {
    bridge   = var.bridge
    model    = "virtio"
    firewall = true
    enabled  = true
  }

  # ✅ Cloud-Init with static IPv4  
  initialization {
    datastore_id = var.datastore_id

    # NOTE: 'hostname' is not supported by this provider.
    # the vm name (var.name) normally used as a  hostname for Cloud-Init.

    ip_config {
      # 'id' is not supported here; used for net0
      ipv4 {
        address = var.talos_ipv4_cidr
        gateway = var.talos_ipv4_gw
      }
      # Para DHCP:
      # ipv4 { address = "dhcp" }
    }
  }

  clone {
    full    = true
    retries = 1
    vm_id   = var.template_vmid
  }

  timeout_start_vm = 300
  timeout_create   = 600
  timeout_stop_vm  = 300

  # --- Verify Cloud-Init and start VM if static ip  show in dump ---
  provisioner "local-exec" {
    # needs 'sshpass' in the machine that run 'terraform apply' ( sudo apt-get install sshpass)
    command = <<-EOT
      set -euo pipefail

      VMID="${self.vm_id}"
      EXPECTED_IP="${var.talos_ipv4_cidr}"
      EXPECTED_GW="${var.talos_ipv4_gw}"
      SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password -o PubkeyAuthentication=no"

      echo "[Cloud-Init check] VMID=$VMID"
      echo "[Cloud-Init check] Esperado IP: $EXPECTED_IP | Gateway: $EXPECTED_GW"

      # 1) network Dump config for Cloud-Init no Proxmox
      NET_DUMP=$(sshpass -p "${var.proxmox_password}" ssh $SSH_OPTS "${var.proxmox_username}@${var.proxmox_host}" "qm cloudinit dump $VMID network" || true)

      echo "[Cloud-Init dump] ============================="
      echo "$NET_DUMP"
      echo "=============================================="

      # 2) Validate if there is an address gateway espected (just restart if both exist)
      MATCH_IP=$(echo "$NET_DUMP" | grep -F "$EXPECTED_IP" || true)
      MATCH_GW=$(echo "$NET_DUMP" | grep -F "$EXPECTED_GW" || true)

      if [ -n "$MATCH_IP" ] && [ -n "$MATCH_GW" ]; then
        echo "[Cloud-Init check] OK: IP/gateway found in dump."
        echo "[Action] Reboot VM $VMID..."
        sshpass -p "${var.proxmox_password}" ssh $SSH_OPTS "${var.proxmox_username}@${var.proxmox_host}" "qm reboot $VMID" || \
        sshpass -p "${var.proxmox_password}" ssh $SSH_OPTS "${var.proxmox_username}@${var.proxmox_host}" "qm reset $VMID"
      else
        echo "[Cloud-Init check] FAILED: IP/gateway not found in dump."
        echo "[Action] will not reboot. Verify block 'initialization.ip_config'."
        exit 0
      fi
    EOT
       interpreter = ["/bin/bash", "-c"]
  }
}
