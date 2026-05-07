#############################################
# Default VPC (fix internet issue)
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

#############################################
# Ubuntu AMI
#############################################
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

  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
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
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.rke_sg.id]

  root_block_device {
    volume_size = 20
  }

  user_data = <<-EOF
#!/bin/bash
hostnamectl set-hostname master
EOF

  tags = { Name = "master" }
}

#############################################
# WORKERS
#############################################
resource "aws_instance" "worker1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.rke_sg.id]

  root_block_device {
    volume_size = 20
  }

  user_data = <<-EOF
#!/bin/bash
hostnamectl set-hostname worker-1
EOF

  tags = { Name = "worker-1" }
}

resource "aws_instance" "worker2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.rke_sg.id]

  root_block_device {
    volume_size = 20
  }

  user_data = <<-EOF
#!/bin/bash
hostnamectl set-hostname worker-2
EOF

  tags = { Name = "worker-2" }
}

#############################################
# RKE Setup
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
    private_key = file("k8s_key.pem")
    host        = aws_instance.master.public_ip
  }

  provisioner "file" {
    source      = "k8s_key.pem"
    destination = "/home/ubuntu/k8s_key.pem"
  }

  provisioner "file" {
    source      = "provision.sh"
    destination = "/home/ubuntu/provision.sh"
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
      "chmod 400 /home/ubuntu/k8s_key.pem",
      "chmod +x /home/ubuntu/provision.sh",
      "/home/ubuntu/provision.sh"
    ]
  }
}