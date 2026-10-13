# Funcionalidades opcionales

Cada una se activa desde la configuración y está apagada por defecto
(decidido 2026-10-13). Pequeñas: se agrupan en un archivo hasta que alguna
crezca lo suficiente para tener el suyo.

## subtitulos

Exportar SRT, VTT y JSON con tiempos, además del `.txt`. Útil sobre todo para
video. Depende de: [marcas-tiempo](marcas-tiempo.md).

## notificaciones

Progreso por archivo, cancelación y notificación del sistema al terminar un
lote. Depende de: [cola-trabajos](cola-trabajos.md).

## accion-original

Qué hacer con el archivo de entrada al terminar: dejarlo, moverlo a una
carpeta de procesados o borrarlo (el script hoy siempre lo mueve). Depende de:
[cola-trabajos](cola-trabajos.md).

## postproceso-llm

Aplicar un prompt de LLM por perfil (resumen, acta, accionables) y guardar el
resultado junto al `.txt`. Si el proveedor es en la nube, el texto sale de la
máquina. **Postergada** (2026-10-13). Depende de:
[perfiles-lote](perfiles-lote.md).
