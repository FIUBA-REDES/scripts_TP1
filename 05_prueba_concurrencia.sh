#!/usr/bin/env bash
# ==============================================================================
# 05_prueba_concurrencia.sh
# Prueba 5: Demostrar que la aplicación funciona correctamente con múltiples
# clientes operando en simultáneo (2 uploads y 2 downloads desde diferentes
# hosts clientes: h1, h2, h3 y h4).
#
# Uso desde las xterm de Mininet (mininet> xterm h1 h2 h3 h4):
#   En h1: ./05_prueba_concurrencia.sh h1
#   En h2: ./05_prueba_concurrencia.sh h2
#   En h3: ./05_prueba_concurrencia.sh h3
#   En h4: ./05_prueba_concurrencia.sh h4
#
# Y al finalizar, en cualquiera de las terminales:
#   ./05_prueba_concurrencia.sh verificar
# ==============================================================================

set -euo pipefail

MODO="${1:-}"
SERVER_IP="${2:-10.0.0.5}"
SERVER_PORT="${3:-5005}"
PROTO="${4:-sack}"

FILES_DIR="./archivos_prueba"
STORAGE_DIR="../TP1/storage"
RECIBIDOS_DIR="./recibidos"

mkdir -p "${RECIBIDOS_DIR}" "${STORAGE_DIR}"

run_h1() {
    echo "[h1 - 10.0.0.1] Iniciando UPLOAD: ${FILES_DIR}/upload_h1.bin -> ${STORAGE_DIR}/subido_h1.bin"
    python3 ../TP1/src/upload -H "${SERVER_IP}" -p "${SERVER_PORT}" \
        -s "${FILES_DIR}/upload_h1.bin" -n "subido_h1.bin" -r "${PROTO}" -v
}

run_h2() {
    echo "[h2 - 10.0.0.2] Iniciando UPLOAD: ${FILES_DIR}/upload_h2.bin -> ${STORAGE_DIR}/subido_h2.bin"
    python3 ../TP1/src/upload -H "${SERVER_IP}" -p "${SERVER_PORT}" \
        -s "${FILES_DIR}/upload_h2.bin" -n "subido_h2.bin" -r "${PROTO}" -v
}

run_h3() {
    echo "[h3 - 10.0.0.3] Iniciando DOWNLOAD: ${STORAGE_DIR}/server_dl_1.bin -> ${RECIBIDOS_DIR}/descargado_h3.bin"
    python3 ../TP1/src/download -H "${SERVER_IP}" -p "${SERVER_PORT}" \
        -d "${RECIBIDOS_DIR}/descargado_h3.bin" -n "server_dl_1.bin" -r "${PROTO}" -v
}

run_h4() {
    echo "[h4 - 10.0.0.4] Iniciando DOWNLOAD: ${STORAGE_DIR}/server_dl_2.bin -> ${RECIBIDOS_DIR}/descargado_h4.bin"
    python3 ../TP1/src/download -H "${SERVER_IP}" -p "${SERVER_PORT}" \
        -d "${RECIBIDOS_DIR}/descargado_h4.bin" -n "server_dl_2.bin" -r "${PROTO}" -v
}

verificar_hashes() {
    echo ""
    echo "=== Verificando integridad (MD5) de las 4 transferencias concurrentes ==="
    local ok=0

    echo "[1] Upload h1:"
    md5sum "${FILES_DIR}/upload_h1.bin" "${STORAGE_DIR}/subido_h1.bin"
    [ "$(md5sum "${FILES_DIR}/upload_h1.bin" | awk '{print $1}')" = "$(md5sum "${STORAGE_DIR}/subido_h1.bin" | awk '{print $1}')" ] || ok=1

    echo "[2] Upload h2:"
    md5sum "${FILES_DIR}/upload_h2.bin" "${STORAGE_DIR}/subido_h2.bin"
    [ "$(md5sum "${FILES_DIR}/upload_h2.bin" | awk '{print $1}')" = "$(md5sum "${STORAGE_DIR}/subido_h2.bin" | awk '{print $1}')" ] || ok=1

    echo "[3] Download h3:"
    md5sum "${STORAGE_DIR}/server_dl_1.bin" "${RECIBIDOS_DIR}/descargado_h3.bin"
    [ "$(md5sum "${STORAGE_DIR}/server_dl_1.bin" | awk '{print $1}')" = "$(md5sum "${RECIBIDOS_DIR}/descargado_h3.bin" | awk '{print $1}')" ] || ok=1

    echo "[4] Download h4:"
    md5sum "${STORAGE_DIR}/server_dl_2.bin" "${RECIBIDOS_DIR}/descargado_h4.bin"
    [ "$(md5sum "${STORAGE_DIR}/server_dl_2.bin" | awk '{print $1}')" = "$(md5sum "${STORAGE_DIR}/descargado_h4.bin" | awk '{print $1}')" ] || ok=1

    if [ "${ok}" -eq 0 ]; then
        echo ""
        echo "[OK] Las 4 transferencias simultáneas finalizaron con hashes idénticos."
    else
        echo ""
        echo "[ERROR] Al menos uno de los archivos transferidos no coincide con el original."
        exit 1
    fi
}

case "${MODO}" in
    h1) run_h1 ;;
    h2) run_h2 ;;
    h3) run_h3 ;;
    h4) run_h4 ;;
    verificar) verificar_hashes ;;
    *)
        echo "Uso (desde la xterm correspondiente): $0 {h1|h2|h3|h4|verificar}"
        exit 1
        ;;
esac
