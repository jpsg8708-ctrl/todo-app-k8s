#!/bin/bash
set -e

echo "==> Verificando kind..."
if ! command -v kind &>/dev/null; then
  echo "    Instalando kind..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
else
  echo "    kind ya está instalado."
fi

echo "==> Verificando kubectl..."
if ! command -v kubectl &>/dev/null; then
  echo "    Instalando kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
else
  echo "    kubectl ya está instalado."
fi

echo "==> Generando kind-config.yaml..."
cat <<KINDEOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5001"]
    endpoint = ["http://registry:5000"]
KINDEOF

echo "==> Creando clúster kind..."
if kind get clusters 2>/dev/null | grep -q "^kind$"; then
  echo "    El clúster 'kind' ya existe, omitiendo creación."
else
  kind create cluster --config kind-config.yaml
fi

echo "==> Conectando registry a la red de kind..."
docker network connect kind registry 2>/dev/null || echo "    Ya estaba conectado."

echo "==> Instalando metrics-server..."
if kubectl get deployment metrics-server -n kube-system &>/dev/null; then
  echo "    metrics-server ya existe."
else
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl patch deployment metrics-server -n kube-system \
    --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--metric-resolution=5s"}]'

  # Esperar al metrics-server con reintentos (en Codespaces puede tardar bastante)
  echo "    Esperando a metrics-server (puede tardar hasta 3 minutos)..."
  METRICS_READY=false
  for attempt in 1 2 3; do
    if kubectl rollout status deployment/metrics-server -n kube-system --timeout=90s 2>/dev/null; then
      METRICS_READY=true
      break
    fi
    echo "    Intento $attempt/3 — metrics-server aún no está listo, reintentando..."
    sleep 10
  done

  if [ "$METRICS_READY" = false ]; then
    echo "    ⚠️  metrics-server tarda más de lo esperado."
    echo "    Continuando... el HPA tardará un poco más en funcionar."
  fi
fi

echo "==> Configurando HPA sync period..."
if docker exec kind-control-plane grep -q "horizontal-pod-autoscaler-sync-period" /etc/kubernetes/manifests/kube-controller-manager.yaml; then
  docker exec kind-control-plane sed -i 's/--horizontal-pod-autoscaler-sync-period=.*/--horizontal-pod-autoscaler-sync-period=10s/' /etc/kubernetes/manifests/kube-controller-manager.yaml
else
  docker exec kind-control-plane sed -i '/- kube-controller-manager/a\    - --horizontal-pod-autoscaler-sync-period=10s' /etc/kubernetes/manifests/kube-controller-manager.yaml
fi
sleep 15

echo ""
echo "✅ Clúster listo."
kubectl get nodes
