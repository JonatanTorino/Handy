# conversion-archivos

Transcribir archivos desde la UI: selector de archivos y arrastrar y soltar.
Encola trabajos en cola-trabajos.

Depende de: [cola-trabajos](cola-trabajos.md), [formatos-media](formatos-media.md).

## Estado

Idea inicial (2026-10-11). Sin diseño.

## Piezas existentes

- `tauri-plugin-dialog` ya instalado (Rust y `@tauri-apps/plugin-dialog`):
  `open({ filters })` para el selector.
- Arrastrar y soltar: `getCurrentWebview().onDragDropEvent()` (Tauri 2)
  entrega rutas reales.

## Propuesta

El formulario de conversión (archivos, modelo, carpeta de salida, opciones)
es un perfil de lote sin guardar. perfiles-lote agrega "guardar como perfil"
sobre el mismo formulario, sin construir otra pantalla.

## Decisiones

Ninguna aún.

## Preguntas abiertas

- ¿Se confirma que el formulario sea un perfil sin guardar?
- Dónde vive en la UI: sección nueva en la barra lateral, o dentro de una
  existente.

## Próximo paso

Esperar cola-trabajos.
