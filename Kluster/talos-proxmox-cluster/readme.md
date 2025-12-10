# talos-proxmox-cluster (Packer + Arch helper -> Talos + Terraform + Ansible)

This repository skeleton automates building a **Talos** golden VM template in **Proxmox** using an **Arch Linux helper ISO** (or other minimal live distro that supports SSH) and **Packer**, then deploying multiple control-plane and worker nodes with **Terraform**, and finally bootstrapping Talos configuration using **Ansible** + `talosctl`.

> Note: This is a community-driven method (Arch helper). Official Talos docs describe manual ISO install with `talosctl`. The helper-OS approach is documented in community repos and blog posts (see README links) and is the most reliable automated path today.

---

## Repo layout

```
talos-proxmox-cluster/
├── README.md
├── packer/
│   ├── talos-arch-helper.pkr.hcl
│   └── scripts/
│       └── provision_write_talos.sh
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

> I used the Arch helper approach. For more background see the Archinstall project: [https://wiki.archlinux.org/title/Archinstall](https://wiki.archlinux.org/title/Archinstall) and the community examples: [https://github.com/kubebn/talos-proxmox-kaas](https://github.com/kubebn/talos-proxmox-kaas) and [https://surajremanan.com/posts/automating-talos-installation-on-proxmox-with-packer-and-terraform/](https://surajremanan.com/posts/automating-talos-installation-on-proxmox-with-packer-and-terraform/)

---

## README.md (generated)

See the README inside this repo in the canvas (it's included as part of the document files). It contains step-by-step usage, variables to edit, and troubleshooting tips. The README references the Archinstall page and community sources.

---

## packer/talos-arch-helper.pkr.hcl

This Packer HCL uses the official HashiCorp Proxmox plugin and boots an Arch ISO, configures networking and SSH using a boot command, then runs a small script (`provision_write_talos.sh`) which downloads a Talos raw image (`.raw.xz`) and writes it to the VM disk (`/dev/sda`). The Packer build then converts the VM into a Proxmox template.

```hcl
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
variable "proxmox_node" { default = "pve-node1" }
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
```

---

## packer/scripts/provision_write_talos.sh

This script runs inside the helper VM (Arch) and downloads the Talos raw image then writes it to disk.

```bash
#!/usr/bin/env bash
set -euo pipefail
IMAGE_URL="$1"
TMP=/tmp/talos.raw.xz

# wait for network
for i in {1..30}; do
  if ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# download
curl -L "$IMAGE_URL" -o "$TMP"

# write to disk
xz -d -c "$TMP" | dd of=/dev/sda bs=4M status=progress conv=fsync
sync

# ensure disk written; poweroff (Packer will convert to template)
poweroff -f
```

---

## terraform/*.tf (minimal example)

`variables.tf` (API token auth recommended):

```hcl
variable "proxmox_api_url" { default = "https://PROXMOX:8006/api2/json" }
variable "proxmox_token_id" { default = "terraform@pam!token" }
variable "proxmox_token_secret" { default = "TOKEN_SECRET" }
variable "target_node" { default = "pve-node1" }
```

`locals.tf` — define counts and per-node sizes or a map:

```hcl
locals {
  masters = {
    "talos-master-1" = { vmid = 101; cores = 2; memory = 2048; disk = 20; }
    "talos-master-2" = { vmid = 102; cores = 2; memory = 2048; disk = 20; }
    "talos-master-3" = { vmid = 103; cores = 2; memory = 2048; disk = 20; }
  }

  workers = {
    "talos-worker-1" = { vmid = 201; cores = 2; memory = 2048; disk = 20; }
    "talos-worker-2" = { vmid = 202; cores = 2; memory = 2048; disk = 20; }
  }
}
```

`main.tf` — clones template and sets resources:

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
  clone       = "talos-arch-helper-template"
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
  clone       = "talos-arch-helper-template"
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

`outputs.tf`:

```hcl
output "masters" {
  value = [for m in proxmox_vm_qemu.masters : m.name]
}

output "workers" {
  value = [for w in proxmox_vm_qemu.workers : w.name]
}
```

---

## ansible/bootstrap-talos.yaml

This playbook applies Talos configurations to the newly created VMs using `talosctl`. Ensure `talosctl` is installed where you run Ansible.

```yaml
---
- name: Bootstrap Talos cluster
  hosts: all
  gather_facts: no
  vars_files:
    - group_vars/all.yaml

  tasks:
    - name: Wait for node API (port 6443)
      ansible.builtin.wait_for:
        host: "{{ ansible_host | default(inventory_hostname) }}"
        port: 6443
        timeout: 300

    - name: Copy Talos config
      ansible.builtin.copy:
        src: "../talos-configs/{{ talos_config }}"
        dest: /tmp/talos-config.yaml

    - name: Apply Talos config with talosctl
      ansible.builtin.command: >
        talosctl --nodes {{ ansible_host | default(inventory_hostname) }} apply-config --insecure --file /tmp/talos-config.yaml
      register: result
      failed_when: result.rc != 0 and result.rc != 2

    - name: Reboot node (if config applied)
      ansible.builtin.command: >
        talosctl --nodes {{ ansible_host | default(inventory_hostname) }} reboot --insecure
      when: result.changed
```

`ansible/inventory.ini.example`:

```ini
[masters]
192.168.100.101
192.168.100.102
192.168.100.103

[workers]
192.168.100.201
192.168.100.202
```

`ansible/group_vars/all.yaml`:

```yaml
# pick config file name based on host; you can also set per-host variables in inventory
# default mapping uses inventory host IPs; set talos_config explicitly per host if needed
controlplane_config: controlplane.yaml
worker_config: worker.yaml

# you can override talos_config via host_vars if you want
```

---

## talos-configs examples

`controlplane.yaml.example` and `worker.yaml.example` are minimal placeholders. You must generate the proper Talos machine config files for your cluster (etcd settings, etc.). See Talos docs for machine config examples.

---

## Usage Summary

1. Upload Arch ISO to Proxmox ISO storage (or change `iso_file` to match your storage label).
2. Edit `packer/talos-arch-helper.pkr.hcl` variables (Proxmox URL, credentials, `talos_image_url` if you want a specific release).
3. Run Packer:

   ```bash
   cd packer
   packer init .
   packer build -var "proxmox_password=..." talos-arch-helper.pkr.hcl
   ```
4. Verify template exists in Proxmox (`talos-arch-helper-template`).
5. Edit Terraform variables to point to your Proxmox API token/URL and desired VM counts/IPs.
6. `terraform init` & `terraform apply` to clone nodes.
7. Populate `ansible/inventory.ini` with the new VMs' IPs and run the playbook to apply Talos configs.

---

## Troubleshooting & Tips

* **Network interface name**: Arch helper boot command assumes `ens18`. Change it to the actual interface (check by manual boot).
* **SSH timeout**: helper VM may take time to start SSH; increase `ssh_timeout` if needed.
* **Use Proxmox API token** (recommended) rather than root password for automation.
* **Test manually first**: boot Arch ISO manually in Proxmox, run the script to write Talos image to disk, boot the VM — ensure it becomes Talos and boots successfully before automating.
* **Logs**: when Packer fails, enable `PACKER_LOG=1` for verbose output.

---

## References

* Talos official docs: [https://docs.siderolabs.com/talos/](https://docs.siderolabs.com/talos/)
* Suraj Remanan blog: [https://surajremanan.com/posts/automating-talos-installation-on-proxmox-with-packer-and-terraform/](https://surajremanan.com/posts/automating-talos-installation-on-proxmox-with-packer-and-terraform/)
* KUBEBN talos-proxmox-kaas repo: [https://github.com/kubebn/talos-proxmox-kaas](https://github.com/kubebn/talos-proxmox-kaas)
* Archinstall guide (useful for understanding Arch installer options): [https://wiki.archlinux.org/title/Archinstall](https://wiki.archlinux.org/title/Archinstall)
