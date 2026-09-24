variable "aws_profile" {
  description = "Perfil de AWS CLI a usar"
  type        = string
  default     = "academy"
}

variable "aws_region" {
  description = "Región de AWS donde se despliega todo"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para correr k3s"
  type        = string
  default     = "t3.small" # suficiente para pruebas con k3s + Traefik + nginx
}

variable "allowed_ssh_cidr" {
  description = "Override opcional. Si se deja en null, Terraform detecta tu IP pública actual y usa /32"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Nombre base para etiquetar los recursos"
  type        = string
  default     = "k3s-webserver"
}
