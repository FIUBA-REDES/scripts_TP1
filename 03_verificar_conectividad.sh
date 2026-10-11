#!/usr/bin/env bash
# ==============================================================================
# 03_verificar_conectividad.sh
# Prueba 2: Comprobar mediante ping que la topología cumple con los parámetros
# de red requeridos (RTT ~40ms y pérdida ~10% por sentido -> ~19% de ping loss).
# Ejecutar desde la xterm de un cliente en Mininet (ej: mininet> xterm h1).
# ==============================================================================

set -euo pipefail

SERVER_IP="${1:-10.0.0.5}"
COUNT="${2:-50}"

echo "=== [Prueba 2] Verificando conectividad y parámetros de red hacia ${SERVER_IP} ==="
echo "    Cliente origen: $(ip -o -4 addr show | awk '!/127.0.0.1/ {print $2, $4}')"
echo "    Enviando ${COUNT} paquetes ICMP (intervalo 0.2s)..."
echo ""

ping -c "${COUNT}" -i 0.2 "${SERVER_IP}"
