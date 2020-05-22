#provider "libvirt" {
#  uri = "qemu:///system"
#}

provider "libvirt" {
#  alias = "server2"
  uri   = "qemu+ssh://padouch@172.16.50.20/system"
}

resource "libvirt_volume" "ubuntu-qcow2" {
  name = "ubuntu-qcow2"
  pool = "data" #CHANGE_ME
#  source = "https://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
  source = "/home/oxus/terraform/test-libvirt/bionic-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool = "data"
}

data "template_file" "user_data" {
  template = file("/home/oxus/terraform/test-libvirt/cloud_ini.cfg")
}

data "template_file" "network_config" {
  template = file("/home/oxus/terraform/test-libvirt/network_config.cfg")
}


# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name = "ubuntu-terraform"
  memory = "512"
  vcpu = 1

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  network_interface {
    bridge = "br0"
  }

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
      type        = "pty"
      target_type = "virtio"
      target_port = "1"
  }

  disk {
       volume_id = "${libvirt_volume.ubuntu-qcow2.id}"
  }
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}

terraform {
  required_version = ">= 0.12"
}