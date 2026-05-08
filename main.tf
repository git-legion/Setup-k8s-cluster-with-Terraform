#############################################
# Internal SSH Key Generation
#############################################
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_auth" {
  key_name   = "internal-k8s-key"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

#############################################
# Data Sources
#############################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

#############################################
# Security Group
#############################################
resource "aws_security_group" "rke_sg" {
  name = "rke-cluster-sg"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################
# MASTER
#############################################
resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.k8s_auth.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.rke_sg.id]

  user_data = "#!/bin/bash\nhostnamectl set-hostname master"

  tags = { Name = "master" }

  provisioner "file" {
    source      = "provision.sh"
    destination = "/home/ubuntu/provision.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa_key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /home/ubuntu/provision.sh", "/home/ubuntu/provision.sh"]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa_key.private_key_pem
      host        = self.public_ip
    }
  }
}

#############################################
# WORKER 1
#############################################
resource "aws_instance" "worker1" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.k8s_auth.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.rke_sg.id]

  user_data = "#!/bin/bash\nhostnamectl set-hostname worker-1"

  tags = { Name = "worker-1" }

  provisioner "file" {
    source      = "provision.sh"
    destination = "/home/ubuntu/provision.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa_key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /home/ubuntu/provision.sh", "/home/ubuntu/provision.sh"]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa_key.private_key_pem
      host        = self.public_ip
    }
  }
}

#############################################
# WORKER 2
#############################################
resource "aws_instance" "worker2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.k8s_auth.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.rke_sg.id]

  user_data = "#!/bin/bash\nhostnamectl set-hostname worker-2"

  tags = { Name = "worker-2" }

  provisioner "file" {
    source      = "provision.sh"
    destination = "/home/ubuntu/provision.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa_key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /home/ubuntu/provision.sh", "/home/ubuntu/provision.sh"]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa_key.private_key_pem
      host        = self.public_ip
    }
  }
}

#############################################
# RKE Orchestration
#############################################
resource "null_resource" "rke_setup" {
  depends_on = [
    aws_instance.master,
    aws_instance.worker1,
    aws_instance.worker2
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa_key.private_key_pem
    host        = aws_instance.master.public_ip
  }

  # Inject the internally generated private key into the Master
  provisioner "remote-exec" {
    inline = [
      "echo '${tls_private_key.rsa_key.private_key_pem}' > /home/ubuntu/id_rsa",
      "chmod 400 /home/ubuntu/id_rsa"
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/cluster.yml.tpl", {
      master_ip  = aws_instance.master.private_ip
      worker1_ip = aws_instance.worker1.private_ip
      worker2_ip = aws_instance.worker2.private_ip
    })
    destination = "/home/ubuntu/cluster.yml"
  }

  provisioner "remote-exec" {
    inline = [
      # Install RKE Binary
      "wget -q https://github.com/rancher/rke/releases/download/v1.4.8/rke_linux-amd64",
      "chmod +x rke_linux-amd64 && sudo mv rke_linux-amd64 /usr/local/bin/rke",
      # Install Kubectl
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl",
      # Deploy Cluster
      "rke up",
      # Config setup
      "echo 'export KUBECONFIG=/home/ubuntu/kube_config_cluster.yml' >> ~/.bashrc",
      "echo \"alias k='kubectl'\" >> ~/.bashrc"
    ]
  }
}