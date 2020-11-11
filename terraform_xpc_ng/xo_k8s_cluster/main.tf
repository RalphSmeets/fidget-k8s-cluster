terraform {
    required_providers {
        xenorchestra = {
            source = "terra-farm/xenorchestra"
            version = "~> 0.5"
        }
    }
}

/*
resource "random_shuffle" "token1" {
  input        = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 6
}

resource "random_shuffle" "token2" {
  input        = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  result_count = 16
}
*/

locals {
    machines = merge( 
        { for idx in toset(range(var.lbs)) : idx+0 => {
            type = "lb"
            name = "${var.name} LoadBalancer ${idx+1}"
            hostname = "lb-${idx+1}"
            hostip = cidrhost(var.base_ip,idx)
        }},
        { for idx in toset(range(var.masters)) : idx+var.lbs => {
            type = "master"
            name = "${var.name} Master ${idx+1}"
            hostname = "master-${idx+1}"
            hostip = cidrhost(var.base_ip,idx+var.lbs)
        }},
        { for idx in toset(range(var.workers)) : idx+var.lbs+var.masters=> {
            type = "worker"
            name = "${var.name} Worker ${idx+1}"
            hostname = "worker-${idx+1}"
            hostip = cidrhost(var.base_ip,idx+var.lbs+var.masters)
        }})

    # kubeadm_token = join(".", [join("",random_shuffle.token1.result), join("",random_shuffle.token2.result)])

    cluster_master = local.machines[var.lbs]

    os_vm = {
      "centos8ci" = {
        template = "CentOS 8 Cloudinit"
        cloud_config = "cloud-init-centos8.tmpl"
        user = "centos"
      },
      "debian10ci" = {
        template = "Debian 10 Cloudinit",
        cloud_config = "cloud-init-debian10.tmpl"
        user = "debian"
      }
    }
}


data "xenorchestra_template" "os_vm_template" {
    name_label = local.os_vm[var.os].template
}

data "xenorchestra_network" "eth0net" {
  name_label = "Pool-wide network associated with eth0"
}

data "xenorchestra_sr" "local_storage" {
  name_label = "Local storage"
}

resource "xenorchestra_vm" "machine" {
    for_each = local.machines
    memory_max = 2*1024*1024*1024
    cpus  = 2
    cloud_config = templatefile("./xo_k8s_cluster/${local.os_vm[var.os].cloud_config}", {
      hostname = each.value.hostname
      hostip = each.value.hostip
      machines = local.machines
      # count = each.key
      # pod_network_cidr = var.pod_network_cidr
      # token = local.kubeadm_token
    })
    name_label = each.value.name
    name_description = "Created By Terraform"
    template = data.xenorchestra_template.os_vm_template.id
    network {
      network_id = data.xenorchestra_network.eth0net.id
    }
    
    disk {
      sr_id = data.xenorchestra_sr.local_storage.id
      name_label = "Created by Terraform"
      size = 32212254720 
    }

    
}

/*
Provision only the machines. We'll use kubespray to configure!

resource "null_resource" "cluster_master" {
  depends_on = [
    xenorchestra_vm.machine
  ]

  connection {
    host = local.machines[var.lbs].hostip
    user = local.os_vm[var.os].user
  }

  provisioner "remote-exec" {
      inline = [
        "sudo cloud-init status --wait",
        "echo sudo kubeadm init --apiserver-advertise-address=${local.machines[var.lbs].hostip} --pod-network-cidr=${var.pod_network_cidr}",
        "sudo kubeadm init --apiserver-advertise-address=${local.machines[var.lbs].hostip} --pod-network-cidr=${var.pod_network_cidr}",
        "mkdir -p $HOME/.kube",
        "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
        "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
        "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
        "kubectl wait --for=condition=available deployment.apps/coredns -n kube-system"
      ]
    }
}

resource "null_resource" "worker" {
  for_each = local.machines
  depends_on = [
    xenorchestra_vm.machine,
    null_resource.cluster_master,
    data.external.kubadm_discovery_token
  ]

  connection {
    host = each.value.hostip
    user = local.os_vm[var.os].user
  }

  provisioner "remote-exec" {
    inline = each.value.type == "worker" ? [
      "sudo cloud-init status --wait",
      "sudo modprobe ip_vs",
      "sudo modprobe ip_vs_rr",
      "sudo modprobe ip_vs_wrr",
      "sudo modprobe ip_vs_sh",
      "echo ip_vs >> /etc/modules",
      "echo ip_vs_rr >> /etc/modules",
      "echo ip_vs_wrr >> /etc/modules",
      "echo ip_vs_sh >> /etc/modules",
      "sudo kubeadm join ${local.machines[var.lbs].hostip}:6443 --token ${local.kubeadm_token} --discovery-token-ca-cert-hash sha256:${data.external.kubadm_discovery_token.result.content} -v=5"
    ] : []
    
  
  }
}*/

output "machines" {
    value = local.machines
}

/*
output "token" {
  value = local.kubeadm_token
}

output "kubadm_discovery_token" {
  value = data.external.kubadm_discovery_token.result.content
}

data "external" "kubadm_discovery_token" {

  depends_on = [
    xenorchestra_vm.machine,
    null_resource.cluster_master
  ]

  program = [
    "sh",
    "-c",
    "jq -n --arg content \"$(ssh -o StrictHostKeyChecking=no ${local.os_vm[var.os].user}@${local.machines[var.lbs].hostip} sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')\" '{$content}' ",
  ]
} */