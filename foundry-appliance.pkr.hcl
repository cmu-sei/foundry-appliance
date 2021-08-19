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

  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    inline            = [
      "echo '${var.appliance_version}' > /etc/appliance_version",
      "swapoff -a",
      "sed -i -r 's/(\\/swap\\.img.*)/#\\1/' /etc/fstab",
      "apt update",
      "apt full-upgrade -y",
      "systemctl disable --now systemd-resolved",
      "rm -f /etc/resolv.conf",
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "apt install -y dnsmasq avahi-daemon jq nfs-common sshpass",
      "mv ~/foundry/dnsmasq.conf /etc/dnsmasq.d/foundry.conf",
      "chown root:root /etc/dnsmasq.d/foundry.conf",
      "systemctl restart dnsmasq",
      "snap install microk8s --classic --channel=1.20/stable",
      "microk8s status --wait-ready",
      "microk8s enable dns storage ingress host-access metrics-server",
      "usermod -a -G microk8s ${var.ssh_username}",
      "chown -f -R ${var.ssh_username}:${var.ssh_username} ~/.kube",
      "sed -i '/^DNS\\.5.*/a DNS.6 = foundry.local' /var/snap/microk8s/current/certs/csr.conf.template",
      "snap install kubectl --classic",
      "snap install helm --classic",
      "curl -sLo /usr/local/bin/cfssl https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl_1.5.0_linux_amd64",
      "curl -sLo /usr/local/bin/cfssljson https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssljson_1.5.0_linux_amd64",
      "chmod +x /usr/local/bin/cfssl*",
      "sudo -u ${var.ssh_username} git clone https://github.com/jaggedmountain/k-alias.git",
      "(cd /usr/local/bin && ln -s ~/k-alias/[h,k]* .)",
      "chmod -x /etc/update-motd.d/00-header",
      "chmod -x /etc/update-motd.d/10-help-text",
      "sed -i -r 's/(ENABLED=)1/\\10/' /etc/default/motd-news",
      "ln -s /home/foundry/foundry/foundry-banner /etc/update-motd.d/05-foundry-banner",
      "sed -i 's/{version}/${var.appliance_version}/' ~/foundry/web/index.html",
      "echo -e 'Foundry Appliance ${var.appliance_version} \\\\n \\l \\n' > /etc/issue",
      "sed -i -r 's/(GRUB_CMDLINE_LINUX_DEFAULT=).*/\\1\"quiet net.ifnames=0 biosdevname=0 ipv6.disable=1\"/' /etc/default/grub",
      "update-grub",
      "reboot"
    ]
  }

  provisioner "shell" {
    inline = [
      "ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ''",
      "microk8s status --wait-ready",
      "microk8s config -l > ~/.kube/config",
      "chmod 600 ~/.kube/config",
      "~/foundry/certs/generate-certs.sh"
    ]
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    inline          = [
      "cp ~/foundry/certs/root-ca.pem /usr/local/share/ca-certificates/foundry-appliance-root-ca.crt",
      "update-ca-certificates",
      "systemctl restart avahi-daemon"
    ]
  }

  provisioner "shell" {
    inline = ["~/foundry/setup-foundry"]
  }

}
