#!/usr/bin/env bash
# ==============================================================================
# 04_transferencia_pipelining.sh
# Pruebas 3, 4 y 7:
#   - Lee contadores de interfaz (ip -s link) antes y después de la transferencia.
#   - Ejecuta la transferencia con protocolo pipelining (sack) midiendo el tiempo.
#   - Calcula e imprime la estimación teórica vs observada de paquetes y retransmisiones.
#   - Verifica integridad mediante comparación de hashes MD5.
#
# Ejecutar desde la xterm de un cliente en Mininet (ej: mininet> xterm h1):
#   ./04_transferencia_pipelining.sh 5MB upload     # Prueba 3 y 4 (5 MB < 2 min)
#   ./04_transferencia_pipelining.sh 1MB upload     # Prueba 7 (1 MB con nuevo delay)
#   ./04_transferencia_pipelining.sh 5MB download   # Variante descargando 5 MB
# ==============================================================================

set -euo pipefail

TAMANIO="${1:-5MB}"       # "5MB" o "1MB"
MODO="${2:-upload}"       # "upload" o "download"
SERVER_IP="${3:-10.0.0.5}"
SERVER_PORT="${4:-5005}"
LOSS_PCT="${5:-10}"       # Tasa de pérdida en % por sentido para la estimación

ARCHIVO_ORIGEN="./archivos_prueba/archivo_${TAMANIO}.bin"
NOMBRE_REMOTO="transfer_${TAMANIO}.bin"
ARCHIVO_SERVIDOR="../TP1/storage/${NOMBRE_REMOTO}"
ARCHIVO_DESCARGADO="./recibidos/descargado_${TAMANIO}.bin"

# Detectar la interfaz de red del host de Mininet (ej: h1-eth0)
IFACE=$(ip -o link show | awk -F': ' '$2 ~ /-eth0/ {split($2,a,"@"); print a[1]; exit}')
if [ -z "${IFACE}" ]; then
    IFACE="lo"
fi

get_iface_stats() {
    # Devuelve: rx_bytes rx_packets tx_bytes tx_packets
    awk -v iface="${IFACE}:" '$1 == iface {print $2, $3, $10, $11}' /proc/net/dev
}

echo "=============================================================================="
echo " Transferencia con Pipelining (SACK) - Modo: ${MODO^^} | Tamaño: ${TAMANIO}"
echo " Interfaz monitoreada: ${IFACE} | Servidor: ${SERVER_IP}:${SERVER_PORT}"
echo "=============================================================================="

# Asegurar que el archivo exista
if [ ! -f "${ARCHIVO_ORIGEN}" ]; then
    echo "[!] No se encontró ${ARCHIVO_ORIGEN}. Ejecutando ./00_preparar_archivos.sh..."
    ./00_preparar_archivos.sh
fi

if [ "${MODO}" = "download" ] && [ ! -f "${ARCHIVO_SERVIDOR}" ]; then
    cp "${ARCHIVO_ORIGEN}" "${ARCHIVO_SERVIDOR}"
fi

echo ""
echo "--- [1] Estado de contadores de red ANTES (ip -s link show ${IFACE}) ---"
ip -s link show "${IFACE}"
read -r RX_BYTES_BEFORE RX_PKTS_BEFORE TX_BYTES_BEFORE TX_PKTS_BEFORE <<< "$(get_iface_stats)"

echo ""
echo "--- [2] Ejecutando transferencia (${MODO} con protocolo sack) ---"
START_TS=$(date +%s.%N)

if [ "${MODO}" = "upload" ]; then
    python3 ../TP1/src/upload \
        -H "${SERVER_IP}" \
        -p "${SERVER_PORT}" \
        -s "${ARCHIVO_ORIGEN}" \
        -n "${NOMBRE_REMOTO}" \
        -r sack \
        -v
    ARCHIVO_FINAL="${ARCHIVO_SERVIDOR}"
else
    mkdir -p ./recibidos
    python3 ../TP1/src/download \
        -H "${SERVER_IP}" \
        -p "${SERVER_PORT}" \
        -d "${ARCHIVO_DESCARGADO}" \
        -n "${NOMBRE_REMOTO}" \
        -r sack \
        -v
    ARCHIVO_FINAL="${ARCHIVO_DESCARGADO}"
fi

END_TS=$(date +%s.%N)

echo ""
echo "--- [3] Estado de contadores de red DESPUÉS (ip -s link show ${IFACE}) ---"
ip -s link show "${IFACE}"
read -r RX_BYTES_AFTER RX_PKTS_AFTER TX_BYTES_AFTER TX_PKTS_AFTER <<< "$(get_iface_stats)"

echo ""
echo "--- [4] Resumen de Tráfico y Estimación de Retransmisiones (Pruebas 4 y 7) ---"
FILE_SIZE_BYTES=$(stat -c%s "${ARCHIVO_ORIGEN}")
python3 - <<EOF
file_size = ${FILE_SIZE_BYTES}
chunk_size = 1024
data_chunks = (file_size + chunk_size - 1) // chunk_size
loss = ${LOSS_PCT} / 100.0
duration = ${END_TS} - ${START_TS}

tx_pkts = ${TX_PKTS_AFTER} - ${TX_PKTS_BEFORE}
rx_pkts = ${RX_PKTS_AFTER} - ${RX_PKTS_BEFORE}
tx_bytes = ${TX_BYTES_AFTER} - ${TX_BYTES_BEFORE}
rx_bytes = ${RX_BYTES_AFTER} - ${RX_BYTES_BEFORE}

# Estimación teórica con pérdida p en cada sentido:
# Si un paquete de datos se pierde con prob p, se esperan N / (1 - p) envíos de datos
# (más reenvíos adicionales si se pierden los ACKs acumulados/SACK).
expected_min_tx = data_chunks / (1.0 - loss)
expected_retrans = expected_min_tx - data_chunks

print(f"Tiempo total de transferencia : {duration:.2f} segundos (límite Prueba 3: 120.00 s)")
print(f"Tamaño del archivo            : {file_size} bytes ({data_chunks} bloques de {chunk_size} B)")
print(f"Paquetes Tx en interfaz       : {tx_pkts} paquetes ({tx_bytes} bytes)")
print(f"Paquetes Rx en interfaz       : {rx_pkts} paquetes ({rx_bytes} bytes)")
if "${MODO}" == "upload":
    obs_retrans = max(0, tx_pkts - data_chunks - 2)
    print(f"Retransmisiones observadas Tx : ~{obs_retrans} paquetes adicionales")
else:
    obs_retrans = max(0, rx_pkts - data_chunks - 2)
    print(f"Retransmisiones recibidas Rx  : ~{obs_retrans} paquetes adicionales")
print(f"Estimación teórica (p={loss*100:.0f}%)   : >= {expected_retrans:.0f} retransmisiones esperadas (~{expected_min_tx:.0f} envíos de DATA)")
EOF

echo ""
echo "--- [5] Verificación de Integridad (MD5) ---"
HASH_ORIG=$(md5sum "${ARCHIVO_ORIGEN}" | awk '{print $1}')
HASH_DEST=$(md5sum "${ARCHIVO_FINAL}" | awk '{print $1}')

echo "MD5 Original    (${ARCHIVO_ORIGEN}): ${HASH_ORIG}"
echo "MD5 Transferido (${ARCHIVO_FINAL}): ${HASH_DEST}"

if [ "${HASH_ORIG}" = "${HASH_DEST}" ]; then
    echo "[OK] Integridad verificada: Los hashes coinciden exactamente."
else
    echo "[ERROR] Los hashes NO coinciden."
    exit 1
fi
