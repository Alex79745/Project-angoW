output "masters" {
  value = [for m in proxmox_vm_qemu.masters : m.name]
}

output "workers" {
  value = [for w in proxmox_vm_qemu.workers : w.name]
}