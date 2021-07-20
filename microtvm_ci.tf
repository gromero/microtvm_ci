terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.10"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://gromero@localhost/system"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data = "${data.template_file.user_data.rendered}"
}

# - Disk 0 -
resource "libvirt_volume" "ubuntu2004_disk" {
  name = "ubuntu2004.qcow2"
  pool = "default"
  source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-disk-kvm.img"
  format = "qcow2"
}

# - VM, Master -
resource "libvirt_domain" "jenkins_master" {
  name   = "Jenkins_master"
  memory = "8192"
  vcpu   = 8

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = "${libvirt_volume.ubuntu2004_disk.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# broken on the first run. understand why
output "ip" {
  value = "${libvirt_domain.jenkins_master.network_interface[0].addresses[0]}"
}
