# talos-proxmox-cluster (Packer + Proxmox + Terraform + Ansible) PAPA

This repository contains a ready-to-use dev/test skeleton to build Talos OS (v1.11) templates in Proxmox using Packer, clone VMs with Terraform, and bootstrap the Talos cluster with Ansible.

---

## Repo layout

```
talos-proxmox-cluster/
├── README.md
├── packer/
│   └── talos.pkr.hcl
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── locals.tf
│   └── outputs.tf
├── ansible/
│   ├── bootstrap-talos.yaml
│   ├── inventory.ini.example
│   └── group_vars/
│       └── all.yaml
└── talos-configs/
    ├── controlplane.yaml.example
    └── worker.yaml.example
```

---

> **Important**: This skeleton is intended for **development/test** use. Adjust credentials, IPs, sizes and secrets before using in production.

---

Open the files below and copy them into the same structure on your machine or Git repo. Each file is ready-to-run aside from a few variables you must set (Proxmox credentials, IPs, and your Talos configs).

---

## README.md

````markdown
# Talos + Proxmox + Terraform + Ansible — Dev/Test Infra (v1.11)

This repo builds a Talos VM template in Proxmox with Packer, clones VMs via Terraform, and bootstraps Talos cluster config using Ansible + talosctl.

## Quick steps

1. Download Talos ISO (v1.11) and upload to Proxmox ISO storage (`local:iso/metal-amd64.iso`).
2. Edit `packer/talos.pkr.hcl` variables for your Proxmox URL/user/password/node.
3. Build template:
   ```bash
   cd packer
   packer init .
   packer validate talos.pkr.hcl
   packer build talos.pkr.hcl
````

4. Edit `terraform/variables.tf` for Proxmox API/token and `terraform/locals.tf` for VM lists/IPs.
5. Deploy VMs:

   ```bash
   cd ../terraform
   terraform init
   terraform apply
   ```
6. Fill `ansible/inventory.ini` with the VMs' IP addresses.
7. Run Ansible to apply Talos configs:

   ```bash
   cd ../ansible
   ansible-playbook -i inventory.ini bootstrap-talos.yaml
   ```

## Notes

* Talos bootstrapping still requires `talosctl` to apply configurations to nodes; Ansible runs `talosctl` commands and thus requires `talosctl` available where Ansible runs.
* For production, prefer Proxmox API tokens over password authentication.

## References

* Talos docs: [https://docs.siderolabs.com/talos/v1.11/](https://docs.siderolabs.com/talos/v1.11/)
* Telmate Packer Proxmox plugin: [https://github.com/Telmate/packer-proxmox](https://github.com/Telmate/packer-proxmox)
* Telmate Terraform Proxmox provider: [https://github.com/Telmate/terraform-provider-proxmox](https://github.com/Telmate/terraform-provider-proxmox)

```
```

---

## packer/talos.pkr.hcl

```hcl
packer {
  required_plugins {
    proxmox = {
      source  = "github.com/Telmate/proxmox"
      version = ">= 1.0.6"
    }
  }
}

variable "proxmox_url" { default = "https://192.168.1.129:8006/api2/json" }
variable "proxmox_user" { default = "root@pam" }
variable "proxmox_password" { default = "REPLACE_WITH_PASSWORD_OR_USE_TOKEN" }
variable "proxmox_node" { default = "pve-node1" }

variable "vm_id" { default = 9700 }
variable "vm_name" { default = "talos-v1.11-template" }
variable "memory" { default = 2048 }
variable "cores" { default = 2 }

source "proxmox-iso" "talos" {
  url      = var.proxmox_url
  username = var.proxmox_user
  password = var.proxmox_password
  node     = var.proxmox_node

  vm_id   = var.vm_id
  vm_name = var.vm_name

  iso_storage_pool = "local"
  iso_file         = "metal-amd64.iso"

  storage_pool = "local-lvm"
  disk_size    = "20G"

  cores  = var.cores
  memory = var.memory

  # Telmate's builder can accept empty ssh fields; avoid provisioning that requires SSH
  ssh_username = ""
  ssh_password = ""

  # network
  bridge        = "vmbr0"
  network_model = "virtio"

  # minimal: no qemu agent
  qemu_agent = false

  # create as template
  convert_to_template = true
}

build {
  sources = ["source.proxmox-iso.talos"]
}
```

---

## terraform/variables.tf

```hcl
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
  description = "Proxmox API token secret"
  type        = string
  default     = "REPLACE_WITH_TOKEN_SECRET"
}

variable "target_node" {
  description = "Proxmox node to spawn VMs on"
  type        = string
  default     = "pve-node1"
}
```

---

## terraform/locals.tf

```hcl
locals {
  masters = {
    "talos-master-1" = { vmid = 101; cores = 2; memory = 2048; disk = 20; ip = "192.168.100.101" }
    "talos-master-2" = { vmid = 102; cores = 2; memory = 2048; disk = 20; ip = "192.168.100.102" }
    "talos-master-3" = { vmid = 103; cores = 2; memory = 2048; disk = 20; ip = "192.168.100.103" }
  }

  workers = {
    "talos-worker-1" = { vmid = 201; cores = 2; memory = 2048; disk = 20; ip = "192.168.100.201" }
    "talos-worker-2" = { vmid = 202; cores = 2; memory = 2048; disk = 20; ip = "192.168.100.202" }
  }
}
```

---

## terraform/main.tf

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url         = var.proxmox_api_url
  pm_api_token_id    = var.proxmox_token_id
  pm_api_token_secret= var.proxmox_token_secret
  pm_tls_insecure    = true
}

resource "proxmox_vm_qemu" "masters" {
  for_each    = local.masters

  vmid        = each.value.vmid
  name        = each.key
  target_node = var.target_node
  clone       = "talos-v1.11-template"
  cores       = each.value.cores
  memory      = each.value.memory

  disk {
    storage = "local-lvm"
    size    = each.value.disk
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}

resource "proxmox_vm_qemu" "workers" {
  for_each    = local.workers

  vmid        = each.value.vmid
  name        = each.key
  target_node = var.target_node
  clone       = "talos-v1.11-template"
  cores       = each.value.cores
  memory      = each.value.memory

  disk {
    storage = "local-lvm"
    size    = each.value.disk
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}
```

---

## terraform/outputs.tf

```hcl
output "master_vmids" {
  value = [for m in proxmox_vm_qemu.masters : m.vmid]
}

output "worker_vmids" {
  value = [for w in proxmox_vm_qemu.workers : w.vmid]
}
```

---

## ansible/bootstrap-talos.yaml

```yaml
---
- name: Bootstrap Talos cluster
  hosts: all
  gather_facts: no
  vars_files:
    - group_vars/all.yaml

  tasks:
    - name: Wait for API (talosctl reachable via node IP) — adjust if needed
      ansible.builtin.wait_for:
        host: "{{ ansible_host | default(inventory_hostname) }}"
        port: 6443
        timeout: 300

    - name: Copy Talos config for control-plane / worker
      ansible.builtin.copy:
        src: "../talos-configs/{{ talos_config }}"
        dest: /tmp/talos-config.yaml

    - name: Apply Talos config using talosctl
      ansible.builtin.command: >
        talosctl --nodes {{ ansible_host | default(inventory_hostname) }} apply-config --insecure --file /tmp/talos-config.yaml
      register: result
      failed_when: result.rc != 0 and result.rc != 2

    - name: Reboot node to run from installed disk (if changed)
      ansible.builtin.command: >
        talosctl --nodes {{ ansible_host | default(inventory_hostname) }} reboot --insecure
      when: result.changed
```

---

## ansible/inventory.ini.example

```ini
[masters]
192.168.100.101
192.168.100.102
192.168.100.103

[workers]
192.168.100.201
192.168.100.202
```

---

## ansible/group_vars/all.yaml

```yaml
# selects controlplane or worker config automatically based on inventory hostname mapping
# By default we assume hosts named talos-master-* are masters; otherwise worker

# simple mapping if you prefer to name hosts
# talos_config: controlplane.yaml

# dynamic selection in playbook uses inventory hostname membership. If you prefer
# explicit mapping, set per host vars in inventory.

# If you store configs in ../talos-configs, set their names here as default
controlplane_config: controlplane.yaml
worker_config: worker.yaml

# talos_config variable is computed by the play via inventory membership logic
```

---

## talos-configs/controlplane.yaml.example

```yaml
# Minimal example Talos control-plane config (example only — adapt networking)
version: v1alpha1
machine:
  type: controlplane
network:
  interfaces:
    - name: eth0
      dhcp: true
# other Talos fields go here: cluster, etcd, etc.
```

---

## talos-configs/worker.yaml.example

```yaml
# Minimal example Talos worker config (example only — adapt networking)
version: v1alpha1
machine:
  type: worker
network:
  interfaces:
    - name: eth0
      dhcp: true
# other Talos fields go here: join config, etc.
```

---

## Final notes & next steps

1. Replace placeholder values: Proxmox credentials, token secrets, and IP addresses.
2. Upload Talos ISO `metal-amd64.iso` to Proxmox ISO storage (UI or `scp`).
3. Run Packer to create template. If you prefer API token auth, update `packer/talos.pkr.hcl` to use `token_id`/`token_secret` arguments.
4. Run Terraform to clone VMs.
5. Populate `ansible/inventory.ini` with the VM IPs and run the ansible playbook.

If you want, I can now:

* create these files as separate individual code files in the canvas
* or produce a downloadable zip containing the skeleton

Which do you prefer? Copy files here, or a zip download?
