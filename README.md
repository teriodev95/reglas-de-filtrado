# Reglas de Filtrado

Documentacion operativa del filtrado autonomo para `solicitudes-app`. El proceso se divide en 7 pasos secuenciales.

## Pasos

| Paso | Archivo | Descripcion |
|---|---|---|
| 1 | [paso-01-toma.md](paso-01-toma.md) | Toma de solicitud — GET, PATCH filtered_by, alertas tempranas |
| 2 | [paso-02-ocr.md](paso-02-ocr.md) | OCR de documentos — INE cliente/aval, comprobantes |
| 3 | [paso-03-correcciones.md](paso-03-correcciones.md) | Correcciones — CURP, no_servicio, nombres, domicilio |
| 4 | [paso-04-personas.md](paso-04-personas.md) | Personas, historial y domicilio — BD + historial API |
| 5 | [paso-05-checks.md](paso-05-checks.md) | Resolucion de checks — todos los c0x/r0x |
| 6 | [paso-06-guardar.md](paso-06-guardar.md) | Guardar resultado — PATCH filtrado con payload completo |
| 7 | [paso-07-verificar.md](paso-07-verificar.md) | Verificar y cerrar — GET de confirmacion + Centrifugo cierre |

## Soporte

- [telegram.md](telegram.md) — Envio y lectura de mensajes via Telegram desde dev

## Alcance

Este repo concentra unicamente las reglas de filtrado. No incluye codigo del backend ni del frontend.
