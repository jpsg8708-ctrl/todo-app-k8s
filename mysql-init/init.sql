CREATE DATABASE IF NOT EXISTS tododb;
USE tododb;

CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO tasks (title, description, completed) VALUES
('Aprender Docker', 'Estudiar contenedores y docker-compose', TRUE),
('Migrar a Kubernetes', 'Aprender K8s y desplegar la aplicación', FALSE),
('Analizar con KICS', 'Detectar y corregir vulnerabilidades', FALSE);
