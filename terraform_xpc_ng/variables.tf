variable "lbs" {
  description = "Number of loadbalancers to initialize"
  default     = 0
}

variable "masters" {
  description = "Number of master to initialize"
  default     = 1
}

variable "workers" {
  description = "Number of workers to initialize"
  default     = 3
}

variable "name" {
  description = "Name of the cluster"
  default     = "Your name!"
}

variable "pod_network_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "service_cidr" {
  type    = string
  default = "10.96.0.0/12"
}

variable "base_ip" {
  default = "192.168.1.224/27"
}

variable "os" {
  default = "debian10ci"
}

variable "ssh_keys" {
  type = list(string)
  default = []
}