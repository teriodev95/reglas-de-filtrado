# Paso 1 — Toma

Marcar la solicitud como en proceso y detectar alertas tempranas.

## Accion

```bash
curl -X PATCH 'https://elysia.xpress1.cc/api/solicitudes-app/{solicitud_id}/filtrado' \
  -H 'Content-Type: application/json' \
  -d '{"filtered_by":"bot","filtered_at":"ISO_UTC"}'
```

## Reglas

- Si `filtrado.filtered_by` ya tiene valor, la solicitud ya fue tomada — no reprocesar
- Si `status = en_filtrado` y `filtered_at` es muy antiguo, puede estar colgada — revisar antes de tomar
- `filtered_at` es la hora real de toma, no `updated_at`

## Status permitidos

| Valor | Significado |
|---|---|
| `capturada` | Recien creada, lista para filtrar |
| `en_filtrado` | Tomada por bot o revisor |
| `en_correccion` | Filtrado cerrado con hallazgos |
| `en_vistos_buenos` | Filtrado cerrado sin hallazgos |
| `lista_desembolso` | Vistos buenos completos |
| `desembolsada` | Desembolsada |
| `rechazada` | Cerrada negativamente |
| `cancelada` | Baja administrativa o duplicado |

## Alertas rapidas a detectar en este paso

- Telefonos placeholder (`1111111111`, `2222222222`)
- Cliente y aval con mismo domicilio capturado
- `agencia`, `gerencia` o `semana` en null
- Misma persona como cliente en otra solicitud activa

## Evento Centrifugo

```json
{
  "channel": "solicitud.{solicitud_id}",
  "data": {
    "type": "bot.message",
    "solicitud_id": "{solicitud_id}",
    "stage": "toma",
    "status": "en_filtrado",
    "message": "Solicitud tomada.",
    "detail": "Se marco en_filtrado con filtered_by y filtered_at.",
    "progress": { "current": 1, "total": 7, "label": "Toma" },
    "meta": { "filtered_by": "bot", "filtered_at": "ISO_UTC" },
    "timestamp": "ISO_UTC"
  }
}
```
