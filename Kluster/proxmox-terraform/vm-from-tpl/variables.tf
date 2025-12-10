variable "template_name" {
  type    = number
  default = 102
}

variable "node_name" {
  type    = string
  default = "KHABC"
}

variable "vm_name" {
  type    = string
  default = "new-creation"
}

variable "vm_id" {
  type    = number
  default = 1233
}

variable "cores" {
  type    = number
  default = 1
}

variable "memory" {
  type    = number
  default = 2048
}

variable "disk_storage" {
  type    = string
  default = "local-lvm"
}

variable "disk_size" {
  type    = string
  default = "32"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "vm_state" {
  type    = string
  default = "running"
}

variable "use_dhcp" {
  type    = bool
  default = true
}
