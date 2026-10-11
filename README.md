# scripts_TP1 - Guía y Scripts para la Demo del TP1

Este repositorio debe estar ubicado en el mismo directorio que el repositorio del `TP1`:
```text
├── TP1/
└── scripts_TP1/
```
Todos los scripts utilizan **rutas relativas** (`../TP1/...`) y están pensados para ejecutarse parados sobre el directorio `scripts_TP1/`.

---

## Estructura de Scripts

| Script | Prueba(s) que cubre | Descripción |
| :--- | :--- | :--- |
| [`00_preparar_archivos.sh`](file:///home/rbarcala/MEGA/Redes/scripts_TP1/00_preparar_archivos.sh) | Preparación | Crea los archivos de prueba (`5MB`, `1MB` y los 4 archivos de concurrencia) y guarda sus hashes MD5 originales. |
| [`01_levantar_topologia.sh`](file:///home/rbarcala/MEGA/Redes/scripts_TP1/01_levantar_topologia.sh) | **Prueba 1 y 6** | Levanta Mininet con 5 hosts (`h1..h4` clientes, `h5` servidor `10.0.0.5`). Sin argumentos usa RTT=40ms y loss=10% por sentido; acepta un nuevo delay por argumento para la Prueba 6. |
| [`02_iniciar_servidor.sh`](file:///home/rbarcala/MEGA/Redes/scripts_TP1/02_iniciar_servidor.sh) | Servidor (`h5`) | Inicia `../TP1/src/start-server` en `10.0.0.5:5005` apuntando a `../TP1/storage`. |
| [`03_verificar_conectividad.sh`](file:///home/rbarcala/MEGA/Redes/scripts_TP1/03_verificar_conectividad.sh) | **Prueba 2** | Ejecuta `ping` hacia `10.0.0.5` para verificar RTT (~40 ms) y tasa de pérdida de paquetes. |
| [`04_transferencia_pipelining.sh`](file:///home/rbarcala/MEGA/Redes/scripts_TP1/04_transferencia_pipelining.sh) | **Pruebas 3, 4 y 7** | Toma foto de contadores (`ip -s link`), transfiere archivo de `5MB` o `1MB` con `sack`, mide tiempo (< 2 min), compara retransmisiones observadas vs teóricas y verifica `md5sum`. |
| [`05_prueba_concurrencia.sh`](file:///home/rbarcala/MEGA/Redes/scripts_TP1/05_prueba_concurrencia.sh) | **Prueba 5** | Ejecuta en simultáneo 2 uploads (`h1`, `h2`) y 2 downloads (`h3`, `h4`) desde distintos clientes y comprueba los 4 hashes MD5. |

---

## Paso a Paso para la Demo

### 0. Preparar archivos (antes de empezar)
```bash
./00_preparar_archivos.sh
```

### 1. Configuración de la topología (10% loss por sentido, RTT 40 ms)
```bash
./01_levantar_topologia.sh
```
> Dentro de la CLI de Mininet, podés abrir terminales con `xterm h1 h2 h3 h4 h5` e iniciar el servidor en `h5`:
> ```bash
> # En h5:
> ./02_iniciar_servidor.sh
> ```
> *(Si querés mostrar Wireshark: abrir otra terminal y correr `sudo wireshark -i s3-eth5 -k -Y "stopwait"`).*

### 2. Verificación de la conectividad
En la terminal de `h1` (o desde Mininet con `h1 ./03_verificar_conectividad.sh`):
```bash
./03_verificar_conectividad.sh
```

### 3 y 4. Transferencia de 5 MB con Pipelining (< 2 min) + Contadores y Retransmisiones
En la terminal de `h1`:
```bash
./04_transferencia_pipelining.sh 5MB upload
```
> - En Wireshark podés filtrar las retransmisiones de un número de secuencia o todos los paquetes DATA con:
>   `stopwait.opcode == 1`

### 5. Prueba de concurrencia (2 Uploads + 2 Downloads en simultáneo)
Podés lanzarlo desde otra terminal en tu host (mientras Mininet y el servidor en `h5` están corriendo):
```bash
./05_prueba_concurrencia.sh auto
```
O bien desde cada `xterm` de `h1`, `h2`, `h3`, `h4`:
```bash
# En h1: ./05_prueba_concurrencia.sh h1
# En h2: ./05_prueba_concurrencia.sh h2
# En h3: ./05_prueba_concurrencia.sh h3
# En h4: ./05_prueba_concurrencia.sh h4
# Y al terminar:
./05_prueba_concurrencia.sh verificar
```

### 6. Cambio de las condiciones de red
Salir de Mininet (`exit`) y reiniciar pasando el nuevo delay por enlace que indique el docente (recuerden que al haber 2 enlaces entre cliente y servidor, `delay_enlace = RTT_deseado / 4`):
```bash
./01_levantar_topologia.sh 25ms
```
*(Volver a levantar `./02_iniciar_servidor.sh` en `h5`).*

### 7. Nueva transferencia de 1 MB y verificación de retransmisiones
En la terminal de `h1`:
```bash
./04_transferencia_pipelining.sh 1MB upload
```