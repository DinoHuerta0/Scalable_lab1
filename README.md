# Lab 1 · Sistemas Escalables

Este repositorio reúne dos proyectos de **infraestructura como código (IaC)** con **Terraform** sobre **AWS**. Ambos despliegan un servidor web en una instancia EC2, pero con distinto nivel de complejidad: uno instala Apache directo en la máquina y el otro usa Kubernetes (k3s).

## Proyectos

### 1. [`AWS_1`](./AWS_1): servidor web en EC2 (capa gratuita)

Despliega una instancia EC2 `t2.micro` con Amazon Linux 2023 que instala y arranca **Apache (`httpd`)** al iniciar.

- Security Group con HTTP (80) y SSH (22) abiertos.
- Outputs: IP pública y URL del sitio.
- Buen punto de partida para aprender lo básico de Terraform y AWS.

### 2. [`k3s_1`](./k3s_1): EC2 + k3s + Traefik + nginx

Despliega una instancia EC2 `t3.small` que instala **k3s** (Kubernetes ligero) y publica un servidor **nginx** a través de un **Ingress** atendido por **Traefik**.

- Genera automáticamente un Key Pair y guarda el `.pem` localmente.
- SSH (22) y API de k3s (6443) abiertos solo a tu IP pública, que se detecta sola.
- Elige de forma automática una zona de disponibilidad compatible con el tipo de instancia.
- Al hacer `destroy`, limpia la huella del host en `known_hosts`.

## Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.3 para `k3s_1`)
- [AWS CLI](https://aws.amazon.com/cli/) con un perfil llamado `academy`
- Windows con PowerShell (lo necesita `k3s_1`)

## Uso rápido

Entra a la carpeta del proyecto que quieras desplegar y ejecuta:

```bash
terraform init
terraform apply
```

Cuando termines, borra los recursos para no generar costos:

```bash
terraform destroy
```

Cada carpeta tiene su propio `README.md` con instrucciones detalladas.
