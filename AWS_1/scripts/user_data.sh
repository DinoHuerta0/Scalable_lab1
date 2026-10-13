#!/bin/bash
set -e

# 1. Instalar y arrancar Apache (httpd)
dnf install -y httpd
systemctl enable --now httpd

# 2. Escribir la landing page de src/ (index.html y styles.css),
#    que Terraform inyecta en las variables index_html y styles_css mediante templatefile()
cat <<'HTML' > /var/www/html/index.html
${index_html}
HTML

cat <<'CSS' > /var/www/html/styles.css
${styles_css}
CSS

# 3. Leer los metadatos de la instancia (IMDSv2) y reemplazar los marcadores de la página
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
md() { curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1"; }

sed -i \
  -e "s/__INSTANCE_ID__/$(md instance-id)/g" \
  -e "s/__AZ__/$(md placement/availability-zone)/g" \
  -e "s/__PRIVATE_IP__/$(md local-ipv4)/g" \
  -e "s/__INSTANCE_TYPE__/$(md instance-type)/g" \
  /var/www/html/index.html
