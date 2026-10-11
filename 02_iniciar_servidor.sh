#!/usr/bin/env bash
# ==============================================================================
# 02_iniciar_servidor.sh
# Inicia el servidor del TP1 en el host h5 (10.0.0.5:5005) usando rutas relativas.
# Ejecutar dentro de la terminal de h5 en Mininet (ej: mininet> xterm h5)
# ==============================================================================

set -euo pipefail

SERVER_IP="${1:-10.0.0.5}"
SERVER_PORT="${2:-5005}"
STORAGE_DIR="../TP1/storage"

mkdir -p "${STORAGE_DIR}"

echo "=== Iniciando servidor en ${SERVER_IP}:${SERVER_PORT} ==="
echo "    Storage: ${STORAGE_DIR}"
echo "    Interfaz activa:"
ip -br addr show

python3 ../TP1/src/start-server -H "${SERVER_IP}" -p "${SERVER_PORT}" -s "${STORAGE_DIR}" -v

