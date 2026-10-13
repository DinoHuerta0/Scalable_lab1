output "website_url" {
  description = "URL del servidor web"
  value       = "http://${aws_instance.web_server.public_ip}"
}

# Ruta del .pem sin comillas para que Terraform no agregue escapes (\")
# y el comando se pueda copiar y pegar directo en Git Bash / bash.
output "ssh_command" {
  description = "Comando para conectarte por SSH (copiar y pegar en bash)"
  value       = "ssh -i ${abspath(local_sensitive_file.private_key.filename)} ec2-user@${aws_instance.web_server.public_ip}"
}
