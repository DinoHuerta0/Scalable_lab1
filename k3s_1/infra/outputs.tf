output "ssh_command" {
  description = "Comando para conectarte por SSH a la instancia"
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ec2-user@${aws_instance.k3s_node.public_ip}"
}

output "webserver_url" {
  description = "URL para ver el WebServer corriendo sobre k3s (vía Traefik, puerto 80)"
  value       = "http://${aws_instance.k3s_node.public_ip}"
}

output "allowed_ssh_cidr" {
  description = "IP/CIDR autorizada para SSH y la API de k3s"
  value       = local.my_ip_cidr
}

output "availability_zone" {
  description = "AZ donde quedó la instancia"
  value       = aws_instance.k3s_node.availability_zone
}
