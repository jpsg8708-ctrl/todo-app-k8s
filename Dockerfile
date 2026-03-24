FROM node:18-alpine

WORKDIR /app

COPY backend/package*.json ./
RUN npm install --production

COPY backend/index.js ./
COPY frontend/ ./public/

# VULNERABILITY FIX: usuario sin privilegios (Kubernetes security)
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

# VULNERABILITY FIX: HEALTHCHECK añadido (LOW - Healthcheck Instruction Missing)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
