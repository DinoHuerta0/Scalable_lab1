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
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro" # capa gratuita
}

variable "allowed_ssh_cidr" {
  description = "Rango de IPs con acceso SSH (por defecto, cualquiera)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "project_name" {
  description = "Nombre base para etiquetar los recursos"
  type        = string
  default     = "web-server"
}
