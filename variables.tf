variable "region" {
  description = "The AWS region to deploy the cluster in"
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "The EC2 instance type for all nodes"
  default     = "t3.small"
}