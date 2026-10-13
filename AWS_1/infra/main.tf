terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# --- AMI más reciente de Amazon Linux 2023 ---
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# --- Security Group: HTTP y SSH ---
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow HTTP and SSH inbound traffic"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
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

# --- Instancia EC2 con Apache ---
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # templatefile inyecta la landing page (src/index.html y src/styles.css) dentro del script
  user_data = templatefile("${path.module}/../scripts/user_data.sh", {
    index_html = file("${path.module}/../src/index.html")
    styles_css = file("${path.module}/../src/styles.css")
  })

  # Si cambia el script o la pagina, recrear la instancia para que user_data vuelva a correr
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-instance"
  }
}

# --- Restringir el .pem solo a tu usuario (Git Bash en Windows, o Linux/Mac) ---
# En Windows, file_permission no se traduce a permisos NTFS, por eso se usa icacls.
# MSYS_NO_PATHCONV=1 evita que Git Bash convierta "/grant:r" en una ruta de archivo.
resource "terraform_data" "fix_pem_permissions" {
  triggers_replace = [local_sensitive_file.private_key.id]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      KEY="${abspath(local_sensitive_file.private_key.filename)}"
      if command -v icacls >/dev/null 2>&1; then
        MSYS_NO_PATHCONV=1 icacls "$KEY" /inheritance:r
        MSYS_NO_PATHCONV=1 icacls "$KEY" /grant:r "$USERNAME:(F)"
      else
        chmod 600 "$KEY"
      fi
    EOT
  }
}

# --- Al destruir la instancia, borrar su huella de ~/.ssh/known_hosts ---
resource "terraform_data" "known_hosts_cleanup" {
  input = aws_instance.web_server.public_ip

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = "ssh-keygen -R ${self.input}"
    on_failure  = continue
  }
}
