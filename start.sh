#!/bin/bash
set -e

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      todo-app — arranque en K8s          ║"
echo "╚══════════════════════════════════════════╝"

# ── 0. Limpieza completa ──────────────────────────────────────
echo ""
echo "▶ [0/7] Limpiando entorno anterior..."

# Matar cualquier port-forward previo
pkill -f "kubectl port-forward" 2>/dev/null || true

# Liberar el puerto 3000 si algo lo ocupa
if lsof -ti:3000 &>/dev/null; then
  echo "    Liberando puerto 3000..."
  kill $(lsof -ti:3000) 2>/dev/null || true
  sleep 1
fi

# Eliminar clúster kind si existe
if command -v kind &>/dev/null && kind get clusters 2>/dev/null | grep -q "^kind$"; then
  echo "    Eliminando clúster kind existente..."
  kind delete cluster 2>/dev/null || true
fi

# Parar y eliminar registry si existe
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^registry$"; then
  echo "    Eliminando registry anterior..."
  docker rm -f registry 2>/dev/null || true
fi

# Liberar el puerto 5001 del registry
if lsof -ti:5001 &>/dev/null; then
  echo "    Liberando puerto 5001..."
  kill $(lsof -ti:5001) 2>/dev/null || true
  sleep 1
fi

echo "    Limpieza completada."

# ── 1. Imágenes en el registry ──────────────────────────────────
echo ""
echo "▶ [1/7] Construyendo y pusheando imágenes..."
bash imagesEnRegistry.sh

# ── 2. Clúster Kubernetes ───────────────────────────────────────
echo ""
echo "▶ [2/7] Creando clúster kind..."
bash createCluster.sh

# ── 3. Secrets y ConfigMap ──────────────────────────────────────
echo ""
echo "▶ [3/7] Aplicando secrets y configmap..."

kubectl create secret generic mysql-secret \
  --from-literal=root-password='rootpassword' \
  --from-literal=user='todouser' \
  --from-literal=password='todopassword' \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap mysql-init-script \
  --from-file=init.sql=mysql-init/init.sql \
  --dry-run=client -o yaml | kubectl apply -f -

# ── Función auxiliar: esperar a que existan pods con un label ──
wait_for_pods_exist() {
  local label=$1
  local max_wait=60
  echo "    Esperando a que los pods ($label) se creen..."
  for i in $(seq 1 $max_wait); do
    if kubectl get pods -l "$label" 2>/dev/null | grep -q .; then
      return 0
    fi
    sleep 2
  done
  echo "    ⚠️ Timeout esperando a que los pods ($label) aparezcan."
  return 1
}

# ── 4. Desplegar MySQL primero ─────────────────────────────────
echo ""
echo "▶ [4/7] Desplegando MySQL..."
kubectl apply -f k8s/mysql-deployment.yml

wait_for_pods_exist "app=mysql"
echo "    Esperando a que MySQL esté ready..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

# ── 5. Desplegar backend y HPA ────────────────────────────────
echo ""
echo "▶ [5/7] Desplegando backend y HPA..."
kubectl apply -f k8s/backend-deployment.yml
kubectl apply -f k8s/backend-hpa.yml

# ── 6. Esperar a que todo esté listo ──────────────────────────
echo ""
echo "▶ [6/7] Esperando a que todos los pods estén listos..."
wait_for_pods_exist "app=backend"
kubectl wait --for=condition=ready pod --all --timeout=300s

echo ""
kubectl get pods,svc,hpa

# ── 7. Exponer la aplicación ──────────────────────────────────
echo ""
echo "▶ [7/7] Iniciando port-forward en puerto 3000..."

# Lanzar port-forward en segundo plano
kubectl port-forward service/backend 3000:3000 &>/dev/null &
PF_PID=$!

# Esperar a que el puerto esté disponible
echo "    Esperando a que el puerto 3000 responda..."
for i in $(seq 1 30); do
  if curl -s http://localhost:3000/health &>/dev/null; then
    echo ""
    echo "✅ ¡Todo listo!"
    echo "   La aplicación está corriendo en: http://localhost:3000"
    echo "   (port-forward PID: $PF_PID)"
    echo ""
    echo "   Para parar: kill $PF_PID"
    exit 0
  fi
  sleep 2
done

echo ""
echo "⚠️  El port-forward se inició pero el health check no responde aún."
echo "   Prueba manualmente: curl http://localhost:3000/health"
echo "   (port-forward PID: $PF_PID)"
