#!/usr/bin/env bash
# ==============================================================================
# 01_levantar_topologia.sh
# Pruebas 1 y 6: Levanta la topología en Mininet con pérdida del 10% en cada
# sentido y RTT de 40 ms por defecto (o con un nuevo delay pasado por parámetro).
#
# Nota sobre los parámetros de enlace (TCLink en topología estrella H1..H5 <-> S3):
# Un paquete entre un cliente (ej. h1) y el servidor (h5) atraviesa 2 enlaces:
#   h1 <---> s3 <---> h5
# Por defecto (sin argumentos), usa ../TP1/src/lib/topologia.py o parámetros equivalentes:
#   - Delay por enlace = 10ms (2 enlaces ida + 2 vuelta = 40ms RTT)
#   - Loss por enlace  = 5%   (~10% de pérdida en cada sentido: 1 - 0.95^2 = 9.75%)
#
# Uso:
#   ./01_levantar_topologia.sh                    # Prueba 1: RTT 40ms (delay=10ms por enlace)
#   ./01_levantar_topologia.sh 25ms               # Prueba 6: Cambia el delay por enlace a 25ms (RTT 100ms)
#   ./01_levantar_topologia.sh 25ms 5             # Prueba 6: Delay por enlace 25ms y loss por enlace 5%
# ==============================================================================

set -euo pipefail

DELAY_ENLACE="${1:-10ms}"
LOSS_ENLACE="${2:-5}"

echo "[*] Limpiando instancias previas de Mininet..."
sudo mn -c

if [ $# -eq 0 ]; then
    echo "=== [Prueba 1] Levantando topología custom desde ../TP1/src/lib/topologia.py ==="
    echo "    (5 hosts: h1..h4 clientes [10.0.0.1..4], h5 servidor [10.0.0.5], RTT=40ms, ~10% loss)"
    sudo mn --custom ../TP1/src/lib/topologia.py --topo mytopo --mac #ver si  lo levantamos sin el .py
else
    echo "=== [Prueba 6] Levantando topología con nuevas condiciones de red ==="
    echo "    Delay por enlace: ${DELAY_ENLACE} | Loss por enlace: ${LOSS_ENLACE}%"
    sudo mn --topo single,5 --link "tc,loss=${LOSS_ENLACE},delay=${DELAY_ENLACE}" --mac
fi

