# Plugins - install with `packer init foundry-appliance.pkr.hcl`
packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variables - override in foundry.auto.pkrvars.hcl
variable "appliance_version" { default = "" }
variable "ssh_username" { default = "foundry" }
variable "ssh_password" { default = "foundry" }
variable "proxmox_url" { default = "" }
variable "proxmox_username" { default = "root@pam" }
variable "proxmox_password" {
  default   = ""
  sensitive = true
}
variable "proxmox_node" { default = "pve.lan" }

locals {
  boot_command = [
    "e<wait>",
    "<down><down><down>",
    "<end><bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  cpus                 = 2
  disk_size_virtualbox = "40000"
  disk_size_proxmox    = "40G"
  iso_url              = "https://releases.ubuntu.com/jammy/ubuntu-22.04.5-live-server-amd64.iso"
  iso_file_proxmox     = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum         = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"
  memory               = 8192
  ssh_timeout          = "30m"
}

source "virtualbox-iso" "foundry-appliance" {
  boot_command         = local.boot_command
  boot_wait            = "5s"
  cpus                 = local.cpus
  disk_size            = local.disk_size_virtualbox
  gfx_controller       = "vmsvga"
  guest_os_type        = "Ubuntu_64"
  hard_drive_interface = "scsi"
  http_directory       = "http"
  iso_checksum         = local.iso_checksum
  iso_url              = local.iso_url
  memory               = local.memory
  output_directory     = "output-virtualbox"
  rtc_time_base        = "UTC"
  shutdown_command     = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password         = var.ssh_password
  ssh_timeout          = local.ssh_timeout
  ssh_username         = var.ssh_username
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--vram", "${local.video_memory}"],
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
  ]
  vm_name = "foundry-appliance-${var.appliance_version}"
}

source "proxmox-iso" "foundry-appliance" {
  boot_command = local.boot_command
  boot_iso {
    type         = "scsi"
    iso_file     = local.iso_file_proxmox
    iso_checksum = local.iso_checksum
    unmount      = true
  }
  boot_wait = "5s"
  cores     = local.cpus
  disks {
    disk_size    = local.disk_size_proxmox
    storage_pool = "local-lvm"
    type         = "scsi"
    format       = "raw"
  }
  http_directory           = "http"
  insecure_skip_tls_verify = true
  memory                   = local.memory
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  node         = var.proxmox_node
  os           = "l26"
  password     = var.proxmox_password
  proxmox_url  = var.proxmox_url
  ssh_password = var.ssh_password
  ssh_timeout  = local.ssh_timeout
  ssh_username = var.ssh_username
  username     = var.proxmox_username
}

build {
  sources = [
    "source.virtualbox-iso.foundry-appliance",
    "source.proxmox-iso.foundry-appliance"
  ]

  provisioner "file" {
    destination = "/home/${var.ssh_username}"
    source      = "./foundry"
  }

  provisioner "file" {
    destination = "/home/${var.ssh_username}"
    source      = "./mkdocs"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "APPLIANCE_VERSION=${var.appliance_version}",
      "SSH_USERNAME=${var.ssh_username}",
    ]
    script = "setup-appliance"
  }

  provisioner "shell" {
    inline = ["~/foundry/install.sh"]
  }
}
