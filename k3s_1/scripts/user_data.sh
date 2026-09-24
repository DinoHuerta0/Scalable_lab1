#!/bin/bash
set -e

# 1. Instalar k3s (server, single-node) CON Traefik habilitado (viene por defecto)
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Esperar a que el nodo esté listo
until /usr/local/bin/k3s kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 5
done

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Esperar a que Traefik (Ingress Controller) esté desplegado y listo
until /usr/local/bin/k3s kubectl get deployment traefik -n kube-system 2>/dev/null | grep -q "1/1"; do
  sleep 5
done

# 2. Desplegar un WebServer simple (nginx) con una página personalizada
cat <<'EOF' > /tmp/webserver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: webserver-html
data:
  index.html: |
    <html>
      <head><title>k3s en EC2</title></head>
      <body style="font-family: sans-serif; text-align: center; margin-top: 10%;">
        <h1>¡Funcionando sobre k3s en EC2!</h1>
        <p>Instancia: $(hostname)</p>
      </body>
    </html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webserver
  template:
    metadata:
      labels:
        app: webserver
    spec:
      containers:
        - name: nginx
          image: nginx:stable-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: html
          configMap:
            name: webserver-html
---
apiVersion: v1
kind: Service
metadata:
  name: webserver
spec:
  type: ClusterIP
  selector:
    app: webserver
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webserver-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: webserver
                port:
                  number: 80
EOF

/usr/local/bin/k3s kubectl apply -f /tmp/webserver.yaml
