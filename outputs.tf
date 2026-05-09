output "master_ip" {
  value = aws_instance.master.public_ip
}

output "kubeconfig_status" {
  value = "Kubeconfig has been automatically configured at ~/.kube/config"
}