terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
#create vpc for k8s_servers
resource "digitalocean_vpc" "vlan-101-k8s" {
  name     = "vlan-101-k8s"
  region   = "nyc3"
  ip_range = "10.10.10.0/24"
}
data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}
#create ansible server
resource "digitalocean_droplet" "ansible" {
  image  = "ubuntu-18-04-x64"
  name = "nypv-ansb1"
  region = "nyc3"
  size   = "s-2vcpu-2gb"
  vpc_uuid = digitalocean_vpc.vlan-101-k8s.id
  ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
    ]
    connection {
      host = self.ipv4_address
      user = "root"
      type = "ssh"
      private_key = file(var.pvt_key)
      timeout = "4m"
    }
    provisioner "remote-exec" {
   inline = [
     "export PATH=$PATH:/usr/bin",
     # install
     "sudo apt-get update",
     "sudo apt install -y software-properties-common",
     "sudo apt-add-repository --yes --update ppa:ansible/ansible",
     "sudo apt install -y ansible",
     "sudo apt install -y git",
     "sudo apt install -y python3-pip",
     "git clone https://github.com/kubernetes-sigs/kubespray.git"
   ]
 }
}
# Create 3 webservers for k8s
resource "digitalocean_droplet" "k8swrk" {
  # ...
  image  = "ubuntu-18-04-x64"
  name   = var.k8s_servers[count.index]
  region = "nyc3"
  size   = "s-2vcpu-2gb"
  count=3
  vpc_uuid = digitalocean_vpc.vlan-101-k8s.id
}
