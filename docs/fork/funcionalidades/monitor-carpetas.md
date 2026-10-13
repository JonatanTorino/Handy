# monitor-carpetas

Vigila las carpetas de entrada de los perfiles de lote seleccionados y encola
automáticamente los archivos nuevos.

Depende de: [perfiles-lote](perfiles-lote.md).

## Estado

Idea inicial (2026-10-11). Sin diseño.

## Requisitos conocidos

- Se activa por perfil (qué perfiles se monitorean).
- No alcanza con los eventos del sistema de archivos:
  - Esperar a que el archivo termine de copiarse o grabarse (tamaño estable y
    apertura exclusiva posible) antes de encolarlo.
  - Al iniciar la app, recorrer las carpetas completas para tomar lo que llegó
    mientras estaba cerrada. La idempotencia la da el registro de
    cola-trabajos.
- Candidato de implementación: crate `notify`.

## Decisiones

Ninguna aún.

## Preguntas abiertas

- ¿Monitoreo recursivo (subcarpetas) o solo el primer nivel?

## Próximo paso

Esperar perfiles-lote.
