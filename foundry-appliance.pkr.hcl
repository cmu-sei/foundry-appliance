source "virtualbox-iso" "foundry-appliance" {
  boot_command         = "${local.boot_command}"
  boot_wait            = "5s"
  cpus                 = "${local.cpus}"
  disk_size            = "${local.disk_size}"
  gfx_controller       = "vmsvga"
  guest_os_type        = "Ubuntu_64"
  hard_drive_interface = "scsi"
  http_directory       = "http"
  iso_checksum         = "${local.iso_checksum}"
  iso_url              = "${local.iso_url}"
  memory               = "${local.memory}"
  output_directory     = "output-virtualbox"
  rtc_time_base        = "UTC"
  shutdown_command     = "${local.shutdown_command}"
  ssh_password         = "${var.ssh_password}"
  ssh_timeout          = "30m"
  ssh_username         = "${var.ssh_username}"
  vm_name              = "foundry-appliance-${var.appliance_version}"
}

source "vmware-iso" "foundry-appliance" {
  boot_command         = "${local.boot_command}"
  boot_wait            = "5s"
  cpus                 = "${local.cpus}"
  disk_size            = "${local.disk_size}"
  guest_os_type        = "ubuntu-64"
  http_directory       = "http"
  iso_checksum         = "${local.iso_checksum}"
  iso_url              = "${local.iso_url}"
  memory               = "${local.memory}"
  network              = "nat"
  network_adapter_type = "vmxnet3"
  output_directory     = "output-vmware"
  shutdown_command     = "${local.shutdown_command}"
  ssh_password         = "${var.ssh_password}"
  ssh_timeout          = "30m"
  ssh_username         = "${var.ssh_username}"
  version              = "14"
  vm_name              = "foundry-appliance-${var.appliance_version}"
}

source "vsphere-iso" "foundry-appliance" {
  boot_command        = "${local.boot_command}"
  boot_wait           = "5s"
  cluster             = "${var.vsphere_cluster}"
  CPUs                = "${local.cpus}"
  datastore           = "${var.vsphere_datastore}"
  guest_os_type       = "ubuntu64Guest"
  http_directory      = "http"
  insecure_connection = true
  iso_checksum        = "${local.iso_checksum}"
  iso_url             = "${local.iso_url}"
  network_adapters {
    network      = "${var.vsphere_network}"
    network_card = "vmxnet3"
  }
  password         = "${var.vsphere_password}"
  RAM              = "${local.memory}"
  shutdown_command = "${local.shutdown_command}"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "30m"
  ssh_username     = "${var.ssh_username}"
  storage {
    disk_size             = "${local.disk_size}"
    disk_thin_provisioned = true
  }
  username       = "${var.vsphere_username}"
  vcenter_server = "${var.vcenter_server}"
  vm_name        = "foundry-appliance-${var.appliance_version}"
}

build {
  sources = [
    "source.virtualbox-iso.foundry-appliance",
    "source.vmware-iso.foundry-appliance",
    "source.vsphere-iso.foundry-appliance"
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
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    environment_vars  = [
      "DEBIAN_FRONTEND=noninteractive",
      "APPLIANCE_VERSION=${var.appliance_version}",
      "SSH_USERNAME=${var.ssh_username}",
    ]
    script            = "install/stage1"
  }

  provisioner "shell" {
    script = "install/stage2"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    script          = "install/stage3"
  }

  provisioner "shell" {
    inline = ["~/foundry/install.sh"]
  }
}
