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
#resource "digitalocean_droplet" "ansible" {
#  image  = "ubuntu-18-04-x64"
#  name = "nypv-ansb1"
#  region = "nyc3"
#  size   = "s-2vcpu-2gb"
#  vpc_uuid = digitalocean_vpc.vlan-101-k8s.id
#  ssh_keys = [
#      data.digitalocean_ssh_key.terraform.id
#    ]
#    connection {
#      host = self.ipv4_address
#      user = "root"
#      type = "ssh"
#      private_key = file(var.pvt_key)
#      timeout = "4m"
#    }
#    provisioner "remote-exec" {
#   inline = [
#     "export PATH=$PATH:/usr/bin",
     # install
#     "sudo apt-get update",
#     "sudo apt install -y software-properties-common",
#     "sudo apt-add-repository --yes --update ppa:ansible/ansible",
#     "sudo apt install -y ansible",
#     "sudo apt install -y git",
#     "sudo apt install -y python3-pip",
#     "git clone https://github.com/kubernetes-sigs/kubespray.git"
#   ]
# }
#}
# Create 3 webservers for k8s
#resource "digitalocean_droplet" "k8swrk" {
  # ...
#  image  = "ubuntu-18-04-x64"
#  name   = var.k8s_servers[count.index]
#  region = "nyc3"
#  size   = "s-2vcpu-2gb"
#  count=3
#  vpc_uuid = digitalocean_vpc.vlan-101-k8s.id
#}

#deploy terraform cluster in digital ocean
resource "digitalocean_kubernetes_cluster" "nypv-k8s01" {
  name    = "nypv-k8s01"
  region  = "nyc3"
  version = "1.20.2-do.0"
  vpc_uuid = digitalocean_vpc.vlan-101-k8s.id

  node_pool {
    name       = "autoscale-worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 5
  }
}

#get your kubernetes configuration to use it in kubernetes
data "digitalocean_kubernetes_cluster" "cluster_data"{
  name= "nypv-k8s01"
  depends_on = [digitalocean_kubernetes_cluster.nypv-k8s01]
}

#define kubernetes config that was retrieved from digital ocean
provider "kubernetes" {
  host             = data.digitalocean_kubernetes_cluster.cluster_data.endpoint
  token            = data.digitalocean_kubernetes_cluster.cluster_data.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.cluster_data.kube_config[0].cluster_ca_certificate
  )
}
#deploy kubernetes namespace
resource "kubernetes_namespace" "example" {
  metadata {
    name = "my-first-namespace"
  }
}

#deploy kubernetes deployment_mode
resource "kubernetes_deployment" "myfirstdeployment" {
  metadata {
    name = "myfirstdeployment"
    labels = {
      test = "myfirstdeployment"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "myfirstdeployment"
      }
    }

    template {
      metadata {
        labels = {
          test = "myfirstdeployment"
        }
      }

      spec {
        container {
          image = "nginx"
          name  = "myfirstpod"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/nginx_status"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}
