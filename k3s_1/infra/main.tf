terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# --- Detectar automáticamente tu IP pública actual ---
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  # Si defines allowed_ssh_cidr se usa ese valor; si no, tu IP detectada /32
  my_ip_cidr = coalesce(var.allowed_ssh_cidr, "${chomp(data.http.my_ip.response_body)}/32")
}

# --- AMI más reciente de Amazon Linux 2023 ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- VPC por defecto (para no complicar el despliegue) ---
data "aws_vpc" "default" {
  default = true
}

# --- AZs donde el tipo de instancia elegido SI está disponible ---
data "aws_ec2_instance_type_offerings" "supported" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

# --- Subnets de la VPC por defecto, solo en AZs compatibles ---
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.supported.locations
  }
}

# --- Security Group: SSH, HTTP directo y NodePort de k3s ---
resource "aws_security_group" "k3s_sg" {
  name        = "${var.project_name}-sg"
  description = "Permite SSH, HTTP y la API de k3s"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  ingress {
    description = "HTTP directo (nginx)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API de k3s (6443) - opcional, para kubectl remoto"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# --- Key Pair generado por Terraform (se crea y destruye con el resto) ---
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# --- Instancia EC2 que corre k3s + el WebServer ---
resource "aws_instance" "k3s_node" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated.key_name
  subnet_id              = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  user_data = file("${path.module}/../scripts/user_data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-instance"
  }
}

# --- Windows: dejar el .pem solo legible por tu usuario (0400 no aplica en Windows) ---
resource "terraform_data" "fix_pem_permissions" {
  triggers_replace = [local_sensitive_file.private_key.id]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command     = <<-EOT
      icacls "${abspath(local_sensitive_file.private_key.filename)}" /inheritance:r
      icacls "${abspath(local_sensitive_file.private_key.filename)}" /grant:r "$${env:USERNAME}:(F)"
    EOT
  }
}

# --- Al destruir la instancia, borrar su huella de ~/.ssh/known_hosts ---
resource "terraform_data" "known_hosts_cleanup" {
  input = aws_instance.k3s_node.public_ip

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command     = "ssh-keygen -R ${self.input}"
    on_failure  = continue
  }
}
