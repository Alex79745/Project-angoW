# Talos + Proxmox + Terraform + Ansible — Dev/Test Infra

This repository provides a fully automated pipeline to:

- Build a **Talos OS (v1.11)** VM template in Proxmox using **Packer**  
- Use **Terraform** to clone multiple control-plane (masters) and worker nodes from that template  
- Bootstrap Talos cluster configuration (control-plane / workers) using **Ansible** + `talosctl`  

> ⚠️ This is designed for **development / test environments**, but can be adapted for production with more care.

---

## 🚀 Workflow Overview

1. Upload the Talos ISO to Proxmox storage  
2. Run Packer to build a VM *template* in Proxmox  
3. Use Terraform to clone as many control-plane and worker VMs as you need  
4. Run Ansible to bootstrap Talos (apply Talos config) — cluster becomes ready  

---

## 🔧 Prerequisites

- Proxmox VE (tested 7.x)  
- Talos v1.11 ISO (uploaded to Proxmox, e.g. `local:iso/metal-amd64.iso`) :contentReference[oaicite:1]{index=1}  
- Packer with Proxmox plugin  
- Terraform (with `Telmate/proxmox` provider)  
- Talosctl (on the machine where Ansible runs)  
- Ansible  

---

## 🧰 Usage Steps

### 1. Upload Talos ISO to Proxmox

```bash
scp metal-amd64.iso root@PROXMOX:/var/lib/vz/template/iso/


cd packer
packer init .
packer validate talos.pkr.hcl
packer build talos.pkr.hcl


cd ../terraform
terraform init
terraform plan
terraform apply

cd ../ansible
ansible-playbook bootstrap-talos.yaml -i inventory.ini
