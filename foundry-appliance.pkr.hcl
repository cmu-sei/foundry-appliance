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
variable "proxmox_node" { default = "pve.lan" }
variable "proxmox_username" { default = "root@pam" }
variable "proxmox_password" {
  default   = ""
  sensitive = true
}
variable "virtualbox_headless" {
  type    = bool
  default = false
}

locals {
  boot_command = [
    "e<wait>",
    "<down><down><down>",
    "<end><bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot_wait            = "5s"
  cpus                 = 2
  disk_size_virtualbox = "40000"
  disk_size_proxmox    = "40G"
  iso_url              = "https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso"
  iso_checksum         = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
  memory               = 8192
  ssh_timeout          = "30m"
}

source "virtualbox-iso" "foundry-appliance" {
  boot_command         = local.boot_command
  boot_wait            = local.boot_wait
  cpus                 = local.cpus
  disk_size            = local.disk_size_virtualbox
  gfx_controller       = "vmsvga"
  guest_os_type        = "Ubuntu_64"
  hard_drive_interface = "scsi"
  headless             = var.virtualbox_headless
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
  vm_name              = "foundry-appliance-${var.appliance_version}"

  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--audio-enabled", "off"]
  ]
}

source "proxmox-iso" "foundry-appliance" {
  boot_command = local.boot_command
  boot_iso {
    type         = "scsi"
    iso_file     = "local:iso/${basename(local.iso_url)}"
    iso_checksum = local.iso_checksum
    unmount      = true
  }
  boot_wait = local.boot_wait
  cores     = local.cpus
  cpu_type  = "x86-64-v2-AES"
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
  node                 = var.proxmox_node
  os                   = "l26"
  password             = var.proxmox_password
  proxmox_url          = var.proxmox_url
  scsi_controller      = "virtio-scsi-single"
  ssh_password         = var.ssh_password
  ssh_timeout          = local.ssh_timeout
  ssh_username         = var.ssh_username
  username             = var.proxmox_username
  vga {
    type = "qxl"
  }
  template_name        = "foundry-appliance-${var.appliance_version}"
  template_description = "Foundry Appliance ${var.appliance_version} - built {{ isotime \"2006-01-02T15:04:05Z\" }}"
}

build {
  sources = [
    "source.virtualbox-iso.foundry-appliance",
    "source.proxmox-iso.foundry-appliance"
  ]

  provisioner "file" {
    source      = "foundry/"
    destination = "/home/${var.ssh_username}"
  }

  provisioner "file" {
    source      = "LICENSE.md"
    destination = "/home/${var.ssh_username}/"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "APPLIANCE_VERSION=${var.appliance_version}",
      "SSH_USERNAME=${var.ssh_username}",
    ]
    script = "setup-appliance.sh"
  }
}
