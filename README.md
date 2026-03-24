# Gestor de Tareas — Aplicación Docker

Aplicación web CRUD multicontenedor para gestión de tareas, construida con:

- **Frontend:** HTML + CSS + JavaScript (vanilla)
- **Backend:** Node.js + Express
- **Base de datos:** MySQL 8.0 (con persistencia)

## Estructura del proyecto

```
.
├── Dockerfile               # Imagen del backend + frontend
├── docker-compose.yml       # Orquestación de contenedores
├── start.sh                 # Script de arranque
├── .dockerignore
├── .gitignore
├── backend/
│   ├── index.js             # Servidor Express con API REST
│   └── package.json
├── frontend/
│   └── index.html           # Interfaz de usuario
└── mysql-init/
    └── init.sql             # Esquema y datos iniciales
```

## Requisitos

- Docker
- Docker Compose

## Cómo arrancar

```bash
chmod +x start.sh
./start.sh
```

O directamente:

```bash
docker compose up --build
```

La aplicación estará disponible en: **http://localhost:3000**

## API REST

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /api/tasks | Listar todas las tareas |
| GET | /api/tasks/:id | Obtener una tarea |
| POST | /api/tasks | Crear tarea |
| PUT | /api/tasks/:id | Actualizar tarea |
| DELETE | /api/tasks/:id | Eliminar tarea |

## Detener la aplicación

```bash
docker compose down
```

Para eliminar también los datos persistidos:

```bash
docker compose down -v
```
