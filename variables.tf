variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.small"
}

variable "key_name" {
  description = "k8s_key"
}

variable "ami" {
  default = "ami-03f4878755434977f" # Ubuntu 22.04 (ap-south-1)
}