# Ruta del .pem sin comillas para que Terraform no agregue escapes (\")
# y el comando se pueda copiar y pegar directo en Git Bash / bash.
output "ssh_command" {
  description = "Comando para conectarte por SSH (copiar y pegar en bash)"
  value       = "ssh -i ${abspath(local_sensitive_file.private_key.filename)} ec2-user@${aws_instance.k3s_node.public_ip}"
}

output "webserver_url" {
  description = "URL del WebServer servido por k3s + Traefik"
  value       = "http://${aws_instance.k3s_node.public_ip}"
}
