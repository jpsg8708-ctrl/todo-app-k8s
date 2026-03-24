#!/bin/bash
set -e

echo "==> Levantando registry local..."
if docker ps -a --format '{{.Names}}' | grep -q "^registry$"; then
  docker start registry 2>/dev/null || true
  echo "    El registry ya existía, arrancado."
else
  docker run -d --name registry --restart=always -p 5001:5000 registry:2
  echo "    Registry creado."
fi

echo "==> Construyendo imagen del backend..."
docker build -t localhost:5001/todo-backend:1.0 .

echo "==> Subiendo imagen al registry..."
docker push localhost:5001/todo-backend:1.0

echo ""
echo "✅ Listo. Imagen disponible en el registry local."
