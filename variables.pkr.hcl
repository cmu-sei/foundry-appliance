variable "appliance_version" {
  type    = string
  default = ""
}

variable "ssh_username" {
  type    = string
  default = "foundry"
}

variable "ssh_password" {
  type      = string
  default   = "foundry"
}

variable "vsphere_cluster" {
  type    = string
  default = ""
}

variable "vsphere_datastore" {
  type    = string
  default = ""
}

variable "vsphere_password" {
  type    = string
  default = ""
  sensitive = true
}

variable "vcenter_server" {
  type    = string
  default = ""
}

variable "vsphere_username" {
  type    = string
  default = ""
}

variable "vsphere_network" {
  type    = string
  default = "VM Network"
}

variable "apps" {
  type = string
  default = "foundry,crucible"
}

variable "cpus" {
  default = 6
}

variable "memory" {
  default = 4098
}

variable "disk_size" {
  default = 30720
}

locals {
  boot_command     = [
  "e<wait>",
  "<down><down><down>",
  "<end><bs><bs><bs><bs><wait>",
  "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
  "<f10><wait>"
  ]
  cpus             = "${var.cpus}"
  disk_size        = "${var.disk_size}"
  iso_url          = "http://www.releases.ubuntu.com/20.04/ubuntu-20.04.3-live-server-amd64.iso"
  iso_checksum     = "sha256:f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
  memory           = "${var.memory}"
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
}
