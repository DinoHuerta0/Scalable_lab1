# Lab 1 · Servidor web en EC2 con Terraform

> Sistemas Escalables — ITESO
> Autor(es): Victor Sebastian Sanchez Silva
> Fecha: 2026-09-12

Este laboratorio despliega un servidor web en una instancia EC2 usando **infraestructura como código (IaC)** con **Terraform** sobre **AWS**. Hay dos versiones del mismo proyecto: una instala **Apache** directo en la máquina y la otra usa **Kubernetes (k3s)** con **Traefik** y **nginx**, como se haría en un clúster on-premise.

---

## Tabla de contenidos
- [Objetivo del laboratorio](#objetivo-del-laboratorio)
- [Proyectos](#proyectos)
- [Comparación](#comparación)
- [Requisitos generales](#requisitos-generales)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Uso rápido](#uso-rápido)
- [Limpieza de recursos](#limpieza-de-recursos)
- [Conclusiones](#conclusiones)
- [Referencias](#referencias)

---

## Objetivo del laboratorio
Lanzar una instancia EC2, desplegar un WebServer simple y conectarse a ella, todo con Terraform y sin pasos manuales en la consola de AWS.

- Crear toda la infraestructura (Security Group, llave SSH, instancia) con Terraform.
- Configurar el servidor automáticamente al arrancar con `user_data`.
- Servir una landing page versionada en el repositorio.
- Conectarse por SSH para revisar y hacer troubleshooting.
- Destruir y recrear el entorno en cada sesión sin dejar recursos.

## Proyectos
Ambos proyectos cumplen el mismo objetivo y sirven la misma landing page; cambia la forma en que se ejecuta y expone el servidor web.

### 1. [`AWS_1`](./AWS_1): Apache directo en EC2 (capa gratuita)
Instancia EC2 `t2.micro` con Amazon Linux 2023 que instala y arranca **Apache (`httpd`)** al iniciar.

- Security Group con HTTP (80) y SSH (22) abiertos; el SSH solo entra con la llave `.pem`.
- La página muestra los datos de la instancia que la atiende, leídos de los metadatos (IMDSv2).
- Buen punto de partida para aprender lo básico de Terraform y AWS.

### 2. [`k3s_1`](./k3s_1): k3s + Traefik + nginx en EC2
Instancia EC2 `t3.small` que instala **k3s** (Kubernetes ligero) y publica **nginx** a través de un **Ingress** atendido por **Traefik**.

- SSH (22) y API de k3s (6443) abiertos solo a tu IP pública, que se detecta sola en cada `apply`.
- Elige automáticamente una zona de disponibilidad que soporte el tipo de instancia.
- Mismo flujo que tendría un clúster on-premise, pero corriendo en la nube.

> Cada carpeta tiene su propio `README.md` con arquitectura, despliegue, verificación y problemas conocidos.

## Comparación
| Aspecto | `AWS_1` | `k3s_1` |
|---------|---------|---------|
| Enfoque | Servidor web directo en la VM | Kubernetes (k3s) sobre la VM |
| Servidor web | Apache `httpd` | nginx (`stable-alpine`) en un pod |
| Cómo se expone | Apache escucha en el puerto 80 | Traefik → Ingress → Service → Pod |
| Tipo de instancia | `t2.micro` (capa gratuita) | `t3.small` |
| Acceso SSH | `0.0.0.0/0` por defecto (configurable) | Solo tu IP `/32`, detectada automáticamente |
| Puertos abiertos | 80, 22 | 80, 22, 6443 |
| Tiempo hasta estar listo | 1 a 2 minutos | 3 a 5 minutos |
| Complejidad | Baja | Media |

**Cuándo conviene cada uno:**
- `AWS_1`: un sitio sencillo con un solo servicio, donde importa el costo y la simplicidad.
- `k3s_1`: cuando se planea crecer a varios servicios, usar manifiestos de Kubernetes o replicar el mismo entorno fuera de AWS.

## Requisitos generales
Los requisitos específicos están en el README de cada carpeta.

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.3 para `k3s_1`).
- [AWS CLI](https://aws.amazon.com/cli/) con el perfil `academy` (`aws sts get-caller-identity --profile academy`).
- **Bash**: en Windows, [Git Bash](https://git-scm.com/downloads); en Linux o Mac, la terminal normal.
- En Windows, **corre Terraform desde Git Bash**, no desde PowerShell ni CMD, para que `bash` apunte al de Git y no al de WSL.

## Estructura del repositorio
```
lab-1/
├── AWS_1/             # Apache directo en EC2
│   ├── infra/         # Terraform (aquí se corren los comandos)
│   ├── scripts/       # user_data.sh
│   ├── src/           # Landing page
│   ├── docs/          # Capturas de evidencia
│   └── README.md
├── k3s_1/             # k3s + Traefik + nginx en EC2
│   ├── infra/
│   ├── scripts/
│   ├── src/
│   ├── docs/
│   └── README.md
├── .gitignore
└── README.md          # Este archivo
```

## Uso rápido
Entra a la carpeta `infra/` del proyecto que quieras desplegar:

```bash
cd AWS_1/infra   # o k3s_1/infra
terraform init
terraform apply
```

Al terminar, Terraform muestra la URL del sitio y el comando SSH. Para conectarte:

```bash
eval "$(terraform output -raw ssh_command)"
```

## Limpieza de recursos
Al terminar cada sesión, desde la carpeta `infra/` del proyecto desplegado:

```bash
terraform destroy
```

Esto borra la instancia, el Security Group, el Key Pair y el `.pem` local, y elimina la huella de la IP en `~/.ssh/known_hosts`.

## Conclusiones
<!-- Ajusta con tus propias observaciones -->

- Ambos enfoques dejan un servidor web funcional con un solo `terraform apply`, sin entrar a la consola de AWS.
- `AWS_1` es más rápido de levantar y cabe en la capa gratuita, pero todo vive en una sola máquina configurada a mano por `user_data`.
- `k3s_1` tarda más y necesita una instancia más grande, pero agrega una capa de orquestación (Ingress, Services, pods) que facilita crecer a más servicios.
- En los dos casos la configuración vive en el repositorio, así que el entorno se reconstruye idéntico en cada sesión.

## Referencias
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EC2 user data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [Apache HTTP Server](https://httpd.apache.org/docs/)
- [Documentación de k3s](https://docs.k3s.io/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

---

**Notas**
- No subas a Git los `.pem` ni los archivos `terraform.tfstate*`: el state contiene la llave privada. Ya están en el `.gitignore` del lab.