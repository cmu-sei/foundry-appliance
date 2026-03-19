# Plugins - install with `packer init crucible-appliance.pkr.hcl`
packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variables - override in crucible.auto.pkrvars.hcl
variable "appliance_version" { default = "" }
variable "ssh_username" { default = "crucible" }
variable "ssh_password" { default = "crucible" }
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
variable "use_cidata" {
  description = "Use a CD-ROM instead of Packer's HTTP server for autoinstall data. Required when the target hypervisor cannot reach Packer's HTTP server (e.g., building from a container)."
  type    = bool
  default = false
}

locals {
  boot_command = var.use_cidata ? [
    "e<wait>",
    "<down><down><down>",
    "<end><bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud ---<wait>",
    "<f10><wait>"
  ] : [
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
  user_data            = file("${path.root}/http/user-data")
}

source "virtualbox-iso" "crucible-appliance" {
  boot_command         = local.boot_command
  boot_wait            = local.boot_wait
  cpus                 = local.cpus
  disk_size            = local.disk_size_virtualbox
  gfx_controller       = "vmsvga"
  guest_os_type        = "Ubuntu_64"
  hard_drive_interface = "scsi"
  headless             = var.virtualbox_headless
  http_directory       = var.use_cidata ? null : "http"
  cd_content           = var.use_cidata ? { "meta-data" = "", "user-data" = local.user_data } : null
  cd_label             = var.use_cidata ? "cidata" : null
  iso_checksum         = local.iso_checksum
  iso_url              = local.iso_url
  memory               = local.memory
  output_directory     = "output-virtualbox"
  rtc_time_base        = "UTC"
  shutdown_command     = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password         = var.ssh_password
  ssh_timeout          = local.ssh_timeout
  ssh_username         = var.ssh_username
  vm_name              = "crucible-appliance-${var.appliance_version}"

  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--audio-enabled", "off"]
  ]
}

source "qemu" "crucible-appliance" {
  boot_command         = local.boot_command
  boot_wait            = local.boot_wait
  cpus                 = local.cpus
  disk_size            = local.disk_size_virtualbox
  format               = "qcow2"
  headless             = true
  http_directory       = var.use_cidata ? null : "http"
  cd_content           = var.use_cidata ? { "meta-data" = "", "user-data" = local.user_data } : null
  cd_label             = var.use_cidata ? "cidata" : null
  iso_checksum         = local.iso_checksum
  iso_url              = local.iso_url
  memory               = local.memory
  output_directory     = "output-qemu"
  accelerator          = "kvm"
  disk_interface       = "virtio-scsi"
  net_device           = "virtio-net"
  shutdown_command     = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password         = var.ssh_password
  ssh_timeout          = local.ssh_timeout
  ssh_username         = var.ssh_username
  vm_name              = "crucible-appliance-${var.appliance_version}"

  // Serial console and QEMU debug logging for CI visibility
  qemuargs = [
    ["-serial", "file:qemu-logs/serial-console.log"],
    ["-d", "guest_errors"],
    ["-D", "qemu-logs/qemu-debug.log"]
  ]
}

source "proxmox-iso" "crucible-appliance" {
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
  http_directory = var.use_cidata ? null : "http"
  dynamic "additional_iso_files" {
    for_each = var.use_cidata ? [1] : []
    content {
      cd_content = {
        "meta-data" = ""
        "user-data" = local.user_data
      }
      cd_label         = "cidata"
      type             = "sata"
      iso_storage_pool = "local"
      unmount          = true
    }
  }
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
  template_name        = "crucible-appliance-${var.appliance_version}"
  template_description = "Crucible Appliance ${var.appliance_version} - built {{ isotime \"2006-01-02T15:04:05Z\" }}"
}

build {
  sources = [
    "source.virtualbox-iso.crucible-appliance",
    "source.qemu.crucible-appliance",
    "source.proxmox-iso.crucible-appliance"
  ]

  provisioner "file" {
    source      = "crucible/"
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
