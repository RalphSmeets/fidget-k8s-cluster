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
    lbs = 0
    masters = 1
    workers = 3
    name = "Fidget"
}

output "machines" {
    value = module.xo_k8s_cluster.machines
}
