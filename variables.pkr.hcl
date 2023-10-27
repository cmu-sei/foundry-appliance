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

locals {
  boot_command     = [
  "e<wait>",
  "<down><down><down>",
  "<end><bs><bs><bs><bs><wait>",
  "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
  "<f10><wait>"
  ]
  cpus             = 2
  disk_size        = 40000
  iso_url          = "https://releases.ubuntu.com/jammy/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum     = "sha256:5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
  memory           = 4096
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  video_memory     = 32
}
