resource "proxmox_vm_qemu" "vm_test"



resource "proxmox_vm_qemu" "vm_test" {


declares a resource block, telling Terraform: “I want to create a Proxmox QEMU/KVM VM.”

"vm_test" is just a local name Terraform uses to reference this VM in this configuration. You can use it in outputs or dependencies.

VM Identification
  vmid        = var.vm_id
  name        = var.vm_name
  target_node = var.node_name


vmid → The unique numeric ID for the VM on Proxmox (like 1233).

name → The human-readable name of the VM (new-creation).

target_node → The Proxmox node that will host the VM (pve).

These tell Proxmox where and how to identify the VM.

Cloning from a template
  clone = var.template_name


Instead of creating a VM from scratch, clone an existing template (omni-talos-tpt).

This makes VM creation fast because the OS and base configuration are already installed in the template.

CPU and Memory
  cores  = var.cores
  memory = var.memory


cores → Number of virtual CPUs (1 in your setup).

memory → Amount of RAM in MB (2048 MB = 2 GB).

These define the hardware resources the VM will get.

Disk configuration
  disk {
    storage   = var.disk_storage
    size      = var.disk_size
    type      = "scsi"
    interface = "virtio0"
  }


storage → Which Proxmox storage to put the VM disk on (local-lvm).

size → Disk size (5 GB).

type → Disk type; SCSI is common for VM templates.

interface → The virtual disk interface; virtio0 is recommended for performance.

Terraform creates a new disk based on the template, storing it on your chosen storage.

Network configuration
  network {
    model  = "virtio"
    bridge = var.bridge
  }


model → The type of virtual NIC (VirtIO is fast and modern).

bridge → The Proxmox bridge the VM will connect to (vmbr0).

 connects the VM to your LAN so it can get an IP via DHCP or use static IP later.

Cloud-init configuration
  os_type   = "cloud-init"
  ipconfig0 = var.use_dhcp ? "ip=dhcp" : "ip=<STATIC_IP>,gw=<GATEWAY>"


os_type → Tells Proxmox this VM will use cloud-init for network/user configuration.

ipconfig0 → The IP setup for the VM’s first NIC:

If use_dhcp is true, Terraform sets it to DHCP.

Otherwise, you can provide a static IP and gateway.

----------------------------------------------------------------------------------