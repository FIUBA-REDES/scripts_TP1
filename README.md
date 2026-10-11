# scripts_TP1 - Guía Paso a Paso para la Demo del TP1

Este repositorio debe estar ubicado en el mismo directorio que el repositorio del `TP1`:
```text
├── TP1/
└── scripts_TP1/
```
Todos los comandos están pensados para **copiar y pegar** parados dentro de la carpeta `scripts_TP1/`.

---

## Paso 0: Preparación inicial (en la Terminal de Linux)

Antes de empezar la demo, abrí una **Terminal de Linux**, entrá a `scripts_TP1/` y ejecutá el script `00` (que instala `xterm` automáticamente si no está instalado y genera todos los archivos de prueba de `5MB`, `1MB` y los de concurrencia con sus hashes MD5):

```bash
# [Terminal de Linux]
sudo apt update && sudo apt install -y xterm
./00_preparar_archivos.sh
```

*(Si también querés asegurarte de tener instalado el plugin de Wireshark del TP1, podés correr una vez `make -C ../TP1 setup`).*

---

## Prueba 1: Configuración de la topología (10% pérdida por sentido y 40 ms RTT)

### 1.1 Levantar Mininet
En la **Terminal de Linux**, levantá la topología custom (`5%` de pérdida y `10 ms` de delay en cada enlace host-switch, lo que acumula **~10% de pérdida en cada sentido** y **40 ms de RTT** entre cualquier cliente y el servidor):

```bash
# [Terminal de Linux]
./01_levantar_topologia.sh
```

### 1.2 Abrir las ventanas de `xterm`
Cuando aparezca el prompt `mininet>`, copiá y pegá esto para abrir las terminales del servidor (`h5`) y de los 4 clientes (`h1`, `h2`, `h3`, `h4`):

```text
xterm h5 h1 h2 h3 h4
```

*(Opcional: si van a mostrar Wireshark en vivo, en otra **Terminal de Linux** ejecutá:)*
```bash
# [Otra Terminal de Linux - Opcional Wireshark]
sudo wireshark -i s3-eth5 -k -Y "stopwait" &
```

### 1.3 Iniciar el servidor en `h5`
En la ventana **`Node: h5` (xterm de h5)**, iniciá el servidor:

```bash
# [xterm h5]
./02_iniciar_servidor.sh
```
*(Dejalo corriendo ahí durante las pruebas 2, 3, 4 y 5).*

---

## Prueba 2: Verificación de la conectividad (`ping`)

En la ventana **`Node: h1` (xterm de h1)**, comprobá con `ping` que el RTT es de ~40 ms y que la pérdida de paquetes coincide con la configurada (~10% en cada sentido $\approx$ 19% de pérdida en ida y vuelta de ICMP):

```bash
# [xterm h1]
./03_verificar_conectividad.sh
```

---

## Pruebas 3 y 4: Transferencia de 5 MB con Pipelining (< 2 min) + Verificación de Retransmisiones e Integridad

En la ventana **`Node: h1` (xterm de h1)**, ejecutá la subida del archivo de 5 MB con protocolo `sack` (pipelining):

```bash
# [xterm h1]
./04_transferencia_pipelining.sh 5MB upload
```

**Qué muestra este script automáticamente en pantalla para mostrarle al docente:**
1. **Contadores Antes (`ip -s link show h1-eth0`)**: paquetes y bytes `RX`/`TX` previos.
2. **Transferencia con Pipelining (`sack`)**: sube `archivo_5MB.bin` en menos de 2 minutos.
3. **Contadores Después (`ip -s link show h1-eth0`)**: paquetes y bytes `RX`/`TX` posteriores.
4. **Estadísticas de Retransmisiones (Prueba 4)**:
   - Tiempo total empleado (< 120 s).
   - Diferencia exacta de paquetes `Tx` y `Rx` en la interfaz del cliente.
   - Cantidad de retransmisiones observadas vs. la estimación teórica ($\frac{N}{1 - p} - N$ con $N = 5120$ paquetes y $p = 0.10$).
5. **Integridad del archivo**: compara el `md5sum` de `./archivos_prueba/archivo_5MB.bin` contra `../TP1/storage/transfer_5MB.bin`.

*(Si el docente pide ver un DOWNLOAD de 5 MB en vez de UPLOAD, el comando es `./04_transferencia_pipelining.sh 5MB download`).*

---

## Prueba 5: Prueba de Concurrencia (2 Uploads y 2 Downloads en simultáneo)

Con el servidor (`./02_iniciar_servidor.sh`) todavía corriendo en **`xterm h5`**, prepará el comando en cada una de las 4 ventanas de cliente (`h1`, `h2`, `h3`, `h4`) y dales `Enter` seguido:

1. En **`Node: h1` (xterm h1)** — *Upload 1*:
   ```bash
   # [xterm h1]
   ./05_prueba_concurrencia.sh h1
   ```

2. En **`Node: h2` (xterm h2)** — *Upload 2*:
   ```bash
   # [xterm h2]
   ./05_prueba_concurrencia.sh h2
   ```

3. En **`Node: h3` (xterm h3)** — *Download 1*:
   ```bash
   # [xterm h3]
   ./05_prueba_concurrencia.sh h3
   ```

4. En **`Node: h4` (xterm h4)** — *Download 2*:
   ```bash
   # [xterm h4]
   ./05_prueba_concurrencia.sh h4
   ```

> **Tip alternativo desde `mininet>`**: Si querés disparar los 4 exactamente en el mismo milisegundo desde la consola `mininet>`, podés pegar esta única línea en `mininet>`:
> ```text
> h1 ./05_prueba_concurrencia.sh h1 & h2 ./05_prueba_concurrencia.sh h2 & h3 ./05_prueba_concurrencia.sh h3 & h4 ./05_prueba_concurrencia.sh h4 &
> ```

### Verificar integridad (MD5) de las 4 transferencias concurrentes
Cuando terminen las 4 transferencias, en **`xterm h1`** (o cualquiera de las terminales) corré:

```bash
# [xterm h1]
./05_prueba_concurrencia.sh verificar
```

---

## Prueba 6: Cambio de las condiciones de red (Nuevo Delay)

1. En la consola de **`mininet>`**, cerrá la topología actual:
   ```text
   exit
   ```

2. En la **Terminal de Linux**, reiniciá la topología pasándole el nuevo delay por enlace que te indique el docente:
   > **Nota importante sobre el delay**: Como cada paquete atraviesa **2 enlaces** a la ida (`h1 -> s3 -> h5`) y **2 enlaces** a la vuelta (`h5 -> s3 -> h1`), el RTT total es **`4 * delay_enlace`** (y el delay de ida es `2 * delay_enlace`).
   > - Ejemplo: si el docente pide **RTT de 100 ms** (50 ms por sentido), pasás `25ms`.
   > - Ejemplo: si el docente pide **delay de 50 ms por enlace**, pasás `50ms`.

   ```bash
   # [Terminal de Linux] (Reemplazar 25ms por el valor indicado por el docente)
   ./01_levantar_topologia.sh 25ms
   ```

3. En el nuevo prompt `mininet>`, volvé a abrir las `xterm` de `h5` y `h1`:
   ```text
   xterm h5 h1
   ```

4. En **`Node: h5` (xterm h5)**, volvé a prender el servidor:
   ```bash
   # [xterm h5]
   ./02_iniciar_servidor.sh
   ```

5. *(Opcional)* En **`Node: h1` (xterm h1)**, verificá con `ping` el nuevo RTT:
   ```bash
   # [xterm h1]
   ./03_verificar_conectividad.sh
   ```

---

## Prueba 7: Nueva transferencia de 1 MB y comprobación de retransmisiones

En la ventana **`Node: h1` (xterm h1)**, ejecutá la transferencia del archivo de **1 MB** con pipelining (`sack`):

```bash
# [xterm h1]
./04_transferencia_pipelining.sh 1MB upload
```

Este comando volverá a mostrar:
- Los contadores de interfaz (`ip -s link`) antes y después.
- El tiempo de transferencia de `archivo_1MB.bin` (1024 bloques de 1 KB).
- Las retransmisiones observadas comparadas contra la estimación teórica para las condiciones de red configuradas.
- La verificación del hash `md5sum` entre el archivo original y el recibido por el servidor.