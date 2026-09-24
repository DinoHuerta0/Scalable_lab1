# EC2 + k3s + Traefik + WebServer con Terraform

Este proyecto lanza **una instancia EC2** (`t3.small`, Amazon Linux 2023), instala **k3s** automáticamente (sin correrlo en local) y despliega un **WebServer (nginx)** expuesto mediante un **Ingress** atendido por **Traefik**, el Ingress Controller que k3s trae por defecto.

## Qué crea Terraform

- **Key Pair** generado automáticamente, con el `.pem` guardado en esta carpeta (`k3s-webserver-key.pem`) y con permisos restringidos a tu usuario de Windows.
- **Security Group** con:
  - Puerto 80 (HTTP) abierto a internet para ver el WebServer.
  - Puertos 22 (SSH) y 6443 (API de k3s) abiertos **solo a tu IP pública actual**, que se detecta sola en cada `apply`.
- **Instancia EC2** en una zona de disponibilidad que soporte el tipo de instancia (se elige sola).
- **k3s + Traefik + nginx**, instalados por `user_data.sh` al arrancar la instancia.

## Requisitos previos

- Terraform >= 1.3
- AWS CLI configurado con el perfil `academy`
- Windows con PowerShell (los pasos automáticos de permisos y limpieza lo usan)

## Desplegar

```powershell
terraform init
terraform apply
```

Al terminar verás estos outputs:

| Output | Qué es |
|---|---|
| `ssh_command` | Comando listo para conectarte por SSH |
| `webserver_url` | URL del WebServer |
| `allowed_ssh_cidr` | IP autorizada para SSH y la API de k3s |
| `availability_zone` | Zona donde quedó la instancia |

> La instancia tarda **3 a 5 minutos** en quedar lista después del `apply`, mientras `user_data.sh` instala k3s y Traefik. Si ves "connection refused" en ese tiempo, es normal: espera y vuelve a intentar.

## Conectarte por SSH

Desde la carpeta del proyecto, usa el comando del output `ssh_command`:

```powershell
ssh -i .\k3s-webserver-key.pem ec2-user@<IP_PUBLICA>
```

La primera vez te preguntará si confías en el servidor; responde `yes`.

## Probar k3s desde dentro de la instancia

Corre estos comandos después de entrar por SSH. Van por capas, de adentro hacia afuera, para que sepas exactamente dónde falla algo.

**0. Ver el progreso de la instalación** (útil si acabas de hacer `apply`)
```bash
sudo tail -f /var/log/cloud-init-output.log
```
Sal con `Ctrl + C`.

**1. Que k3s esté vivo**
```bash
sudo systemctl status k3s --no-pager
sudo k3s kubectl get nodes
```
El nodo debe aparecer en `Ready`.

**2. Que los pods estén corriendo**
```bash
sudo k3s kubectl get pods -A
```
Deben estar en `Running`: `webserver-...` (namespace `default`), y `traefik-...` y `svclb-traefik-...` (namespace `kube-system`).

**3. Que nginx responda dentro del clúster (sin Traefik)**
```bash
sudo k3s kubectl run test --rm -it --image=busybox --restart=Never -- wget -qO- http://webserver
```
Debe imprimir el HTML de la página.

**4. Que Traefik y el Ingress estén configurados**
```bash
sudo k3s kubectl get ingress
sudo k3s kubectl get svc -n kube-system traefik
```
El Service de Traefik debe mostrar el puerto `80:xxxxx` y una `EXTERNAL-IP`.

**5. Que el puerto 80 responda en la instancia**
```bash
curl -v http://localhost
```

**6. Ver todo junto**
```bash
sudo k3s kubectl get pods,svc,ingress -A -o wide
```

**Cómo interpretar los resultados**

| Resultado | Dónde está el problema |
|---|---|
| Falla el paso 3 | Pod o Service de nginx |
| Pasa el 3, falla el 5 | Traefik o el Ingress |
| Pasa el 5, pero no abre desde tu navegador | Red de AWS (Security Group) |

## Ver el WebServer

Abre en el navegador la URL del output `webserver_url`:
```
http://<IP_PUBLICA>
```

## Destruir todo al terminar la sesión

```powershell
terraform destroy
```

Esto borra la instancia, el Security Group, el Key Pair y el `.pem` local. Además, elimina automáticamente la huella de la IP en `C:\Users\<tu_usuario>\.ssh\known_hosts`, así que no queda nada que limpiar a mano.

## Sobre la IP autorizada para SSH

Terraform consulta tu IP pública en cada `apply` (en `https://checkip.amazonaws.com`) y la usa con `/32`, es decir, solo esa dirección exacta. Si cambias de red, corre `terraform apply` otra vez y el Security Group se actualiza sin recrear la instancia.

Para forzar otra IP:
```powershell
terraform apply -var="allowed_ssh_cidr=1.2.3.4/32"
```

## Notas

- No subas a Git el `.pem` ni los archivos `terraform.tfstate*`: el state contiene la llave privada. Agrégalos a `.gitignore`.
- Los pasos automáticos de permisos del `.pem` y de limpieza de `known_hosts` usan PowerShell. Si corres el proyecto desde Linux o Mac, hay que cambiar el `interpreter` en `main.tf`.
- En las descripciones del Security Group no uses acentos ni ñ: AWS las rechaza.
