# Documentación del fork

Funcionalidades propias de este fork (JonatanTorino/Handy) que no existen en
upstream (cjpais/Handy). Esta carpeta es la **fuente de verdad entre sesiones**:
una sesión nueva retoma el trabajo desde acá, sin releer conversaciones viejas.

## Cómo se lee

1. [`mapa.md`](mapa.md): qué funcionalidades hay, cuáles son base de otras y
   en qué orden se hacen. Siempre se lee.
2. `funcionalidades/<clave>.md`: solo el de la funcionalidad en curso. Cada
   archivo enlaza únicamente a sus dependencias directas; no se recorre el
   resto del árbol salvo que haga falta.

Cada archivo de funcionalidad tiene: objetivo, estado, dependencias,
decisiones (con fecha y motivo), preguntas abiertas y próximo paso.

## Protocolo de sesión

- **Al empezar:** leer `mapa.md` y el archivo de la funcionalidad. Lo que no
  esté escrito ahí no está decidido.
- **Al cerrar un intercambio que decide algo:** actualizar el archivo de la
  funcionalidad (decisiones, preguntas, próximo paso), commit `docs:` y push.
  Una sesión abandonada no debe perder decisiones.
- **Para retomar en una sesión nueva:**
  `Continuá la funcionalidad <clave> según docs/fork. Próximo paso: <...>.`

## Ramas

| Rama              | Contenido                                                              |
| ----------------- | ---------------------------------------------------------------------- |
| `main` (del fork) | Integración: upstream + funcionalidades terminadas. Lo que se instala. |
| `feat/<clave>`    | Una funcionalidad. Sale de `main` y vuelve a `main` con squash merge.  |
| remoto `upstream` | cjpais/Handy. Se mergea en `main` cuando se quieran sus mejoras.       |

- Un commit por funcionalidad en `main` (squash merge).
- Una funcionalidad que depende de otra sale de `main` **después** de que la
  dependencia se mergeó. No se apilan ramas.
- Estado: propuesto el 2026-10-13, pendiente de confirmación (ver
  [`mapa.md`](mapa.md#decisiones-globales)).

## Reglas de código

- Lo nuevo va en módulos/archivos nuevos. En archivos de upstream, solo el
  "enganche" mínimo (registrar un comando, un módulo, una ruta de UI). Motivo:
  cada merge de upstream compara línea por línea; los archivos nuevos nunca
  generan conflictos.
- No se modifica el historial estándar de Handy.
- Toda funcionalidad extra es opcional y se activa desde la configuración.
