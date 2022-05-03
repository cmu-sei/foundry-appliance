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
    "<wait><enter><enter><f6><esc><wait> ",
    "net.ifnames=0 biosdevname=0 autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter>",
    "<wait10><wait10><wait10><wait10><wait10><wait10>"
  ]
  cpus             = 2
  disk_size        = 30000
  iso_url          = "https://releases.ubuntu.com/20.04/ubuntu-20.04.4-live-server-amd64.iso"
  iso_checksum     = "sha256:28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"
  memory           = 4096
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
}
