# AWS Free Tier EC2 Web Server con Terraform

Este proyecto contiene la configuración de infraestructura como código (IaC) en Terraform para desplegar automáticamente un servidor web en una instancia EC2 de AWS (usando la capa gratuita).

## Características

- **Instancia EC2**: Despliega una máquina `t2.micro` utilizando la última imagen de Amazon Linux 2023.
- **Servidor Web**: Instala y arranca automáticamente un servidor web Apache (`httpd`) utilizando un script de inicio (`user_data`).
- **Seguridad**: Incluye un Security Group (Grupo de Seguridad) preconfigurado que permite tráfico entrante HTTP (puerto 80) para acceder a la web y SSH (puerto 22) para administración.

## Requisitos Previos

Antes de desplegar este proyecto, asegúrate de tener instalado y configurado lo siguiente:

1. **Terraform**: [Descargar e instalar Terraform](https://developer.hashicorp.com/terraform/downloads).
2. **AWS CLI**: [Descargar e instalar AWS CLI](https://aws.amazon.com/cli/).
3. **Perfil de AWS**: Debes tener configurado un perfil en el AWS CLI llamado `academy` con tus credenciales válidas. 
   Puedes configurarlo corriendo:
   ```bash
   aws configure --profile academy
   ```

## Instrucciones de Uso

Sigue estos pasos en tu terminal desde la raíz de este directorio:

1. **Inicializar Terraform**:
   Descarga los plugins y proveedores necesarios para AWS.
   ```bash
   terraform init
   ```

2. **Revisar el Plan de Ejecución** (Opcional):
   Verifica exactamente qué recursos se van a crear en tu cuenta de AWS sin realizar ningún cambio.
   ```bash
   terraform plan
   ```

3. **Desplegar la Infraestructura**:
   Aplica los cambios y levanta la infraestructura. Te pedirá que escribas `yes` para confirmar.
   ```bash
   terraform apply
   ```

## Accediendo a tu Servidor

Una vez que el comando `terraform apply` termine con éxito, Terraform te mostrará en la terminal las siguientes variables de salida (Outputs):

- `public_ip`: La dirección IP pública asignada a tu servidor.
- `website_url`: Un enlace directo a tu nueva página web.

*Nota: Una vez que la instancia EC2 se reporta como "creada", el servidor Apache puede tardar de 1 a 2 minutos extra en instalarse y arrancar. Si el enlace web no funciona inmediatamente, dale un minuto y recarga la página.*

## Limpieza (Apagar todo)

Cuando termines de usar el servidor web y ya no lo necesites, asegúrate de destruir la infraestructura para mantener tu cuenta limpia.

```bash
terraform destroy
```
Te pedirá que confirmes escribiendo `yes`. Esto borrará permanentemente la instancia EC2 y el Security Group que creaste.
