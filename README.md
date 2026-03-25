# Gestor de Tareas — Aplicación Kubernetes + KICS

Aplicación web CRUD multicontenedor para gestión de tareas, migrada a Kubernetes y analizada con KICS.

Construida con:
- **Frontend:** HTML + CSS + JavaScript (vanilla)
- **Backend:** Node.js + Express
- **Base de datos:** MySQL 8.0 (con persistencia)
- **Orquestación:** Kubernetes (kind) con escalado HPA
- **Seguridad:** Analizada y corregida con KICS

## Estructura del proyecto

```
.
├── Dockerfile                  # Imagen del backend + frontend (usuario sin privilegios)
├── docker-compose.yml          # Para desarrollo local (con correcciones de seguridad)
├── start.sh                    # Script de arranque en K8s
├── createCluster.sh            # Crea el clúster kind con registry local
├── imagesEnRegistry.sh         # Sube imágenes al registry local
├── kind-config.yaml            # Configuración del clúster kind
├── backend/
│   ├── index.js
│   └── package.json
├── frontend/
│   └── index.html
├── mysql-init/
│   └── init.sql
└── k8s/
    ├── backend-deployment.yml  # Deployment + Service (con correcciones KICS)
    ├── mysql-deployment.yml    # Deployment + Service (con correcciones KICS)
    └── backend-hpa.yml         # HorizontalPodAutoscaler (escalado automático)
```

## Requisitos

- Docker
- kind (Kubernetes in Docker)
- kubectl

## Cómo arrancar

```bash
chmod +x start.sh
./start.sh
```

La aplicación estará disponible en: http://localhost:30000

## Escalado automático (HPA)

- Mínimo: 1 réplica
- Máximo: 8 réplicas
- Métrica: CPU > 20%

## Correcciones de seguridad KICS

- **Dockerfile:** usuario sin privilegios, HEALTHCHECK
- **docker-compose.yml:** secretos en variables de entorno, límites CPU/memoria, security_opt, puerto MySQL no expuesto
- **k8s/backend-deployment.yml:** securityContext, runAsNonRoot, readOnlyRootFilesystem, drop capabilities, probes, automountServiceAccountToken
- **k8s/mysql-deployment.yml:** securityContext, runAsNonRoot, drop capabilities, probes, automountServiceAccountToken

## API REST

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /api/tasks | Listar todas las tareas |
| GET | /api/tasks/:id | Obtener una tarea |
| POST | /api/tasks | Crear tarea |
| PUT | /api/tasks/:id | Actualizar tarea |
| DELETE | /api/tasks/:id | Eliminar tarea |
| GET | /health | Health check |
