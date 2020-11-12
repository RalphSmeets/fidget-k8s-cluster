terraform {
    required_providers {
        xenorchestra = {
            source = "terra-farm/xenorchestra"
        }
    }
}

provider "xenorchestra" {
    url = "ws://192.168.1.27"
    username = "ralph.smeets@gmail.com"
    password = "VFzT0fnzxoa"
}

module "xo_k8s_cluster" {
    source = "./xo_k8s_cluster"
    lbs = var.lbs
    masters = var.masters
    workers = var.workers
    name = var.name
    ssh_keys = [
        "ssh-rsa key1",
        "ssh-rsa key1"
    ]
}

output "machines" {
    value = module.xo_k8s_cluster.machines
}
