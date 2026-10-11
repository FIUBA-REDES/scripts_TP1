#!/usr/bin/env bash
# ==============================================================================
# 00_preparar_archivos.sh
# Crea los directorios y archivos de prueba (5MB, 1MB y concurrencia) usando
# rutas relativas respecto a ../TP1
# ==============================================================================

set -euo pipefail

TP1_DIR="../TP1"
FILES_DIR="./archivos_prueba"
STORAGE_DIR="${TP1_DIR}/storage"
RECIBIDOS_DIR="./recibidos"

echo "=== Preparando entorno y archivos de prueba ==="

if ! command -v xterm >/dev/null 2>&1; then
    echo "[*] Instalando xterm..."
    sudo apt-get update && sudo apt-get install -y xterm
fi

mkdir -p "${FILES_DIR}"
mkdir -p "${STORAGE_DIR}"
mkdir -p "${RECIBIDOS_DIR}"

# 1. Archivo de 5 MB (Prueba 3: Transferencia con pipelining < 2 min)
echo "[*] Generando archivo de 5 MB (${FILES_DIR}/archivo_5MB.bin)..."
dd if=/dev/urandom of="${FILES_DIR}/archivo_5MB.bin" bs=1M count=5 status=none

# 2. Archivo de 1 MB (Prueba 7: Nueva transferencia tras cambio de delay)
echo "[*] Generando archivo de 1 MB (${FILES_DIR}/archivo_1MB.bin)..."
dd if=/dev/urandom of="${FILES_DIR}/archivo_1MB.bin" bs=1M count=1 status=none

# 3. Archivos para Prueba 5: Concurrencia (2 uploads desde h1/h2, 2 downloads desde h3/h4)
echo "[*] Generando archivos para prueba de concurrencia (1 MB c/u)..."
dd if=/dev/urandom of="${FILES_DIR}/upload_h1.bin" bs=1M count=1 status=none
dd if=/dev/urandom of="${FILES_DIR}/upload_h2.bin" bs=1M count=1 status=none

# Pre-cargamos en el storage del servidor los archivos que descargarán h3 y h4
dd if=/dev/urandom of="${STORAGE_DIR}/server_dl_1.bin" bs=1M count=1 status=none
dd if=/dev/urandom of="${STORAGE_DIR}/server_dl_2.bin" bs=1M count=1 status=none

echo ""
echo "=== Hashes MD5 de referencia ==="
md5sum "${FILES_DIR}/archivo_5MB.bin" \
       "${FILES_DIR}/archivo_1MB.bin" \
       "${FILES_DIR}/upload_h1.bin" \
       "${FILES_DIR}/upload_h2.bin" \
       "${STORAGE_DIR}/server_dl_1.bin" \
       "${STORAGE_DIR}/server_dl_2.bin" | tee "${FILES_DIR}/hashes_originales.md5"

echo ""
echo "[OK] Archivos listos."

