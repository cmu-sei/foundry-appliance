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
    "<enter><enter><f6><esc><wait> ",
    "net.ifnames=0 biosdevname=0 ipv6.disable=1 autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter>",
    "<wait10><wait10><wait10><wait10><wait10><wait10>"
  ]
  cpus             = 2
  disk_size        = 20000
  iso_url          = "http://releases.ubuntu.com/20.04/ubuntu-20.04.2-live-server-amd64.iso"
  iso_checksum     = "sha256:d1f2bf834bbe9bb43faf16f9be992a6f3935e65be0edece1dee2aa6eb1767423"
  memory           = 4096
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
}
