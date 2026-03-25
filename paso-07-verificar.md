# Paso 7 — Verificar y Cerrar

Leer la solicitud de nuevo y confirmar que todo quedo alineado.

## GET de verificacion

```bash
curl 'https://elysia.xpress1.cc/api/solicitudes-app/{solicitud_id}'
```

## Que verificar

| Campo | Esperado para sin_hallazgos | Esperado para requiere_correccion |
|---|---|---|
| `status` | `en_vistos_buenos` | `en_correccion` |
| `filtrado.status` | `sin_hallazgos` | `requiere_correccion` |
| `ruta_solicitud.paso_actual` | `vistos_buenos` | `filtrado` |
| `filtrado.filtered_by` | `bot` | `bot` |
| `filtrado.diagnostico` | texto descriptivo | texto descriptivo |
| `contexto_filtrado.cliente.comprobante_domicilio` | hidratado | hidratado |
| `contexto_filtrado.aval.comprobante_domicilio` | hidratado | hidratado |

## Si hay desalineacion

- `status` no cambio → el PATCH no se aplico correctamente, reintentar
- `contexto_filtrado` incompleto → hacer PATCH solo del contexto preservando status y checks actuales
- `filtrado.status` no refleja lo enviado → revisar payload, puede haber un campo mal formado

## Regla de contexto incompleto

Si el filtrado ya esta cerrado pero el `contexto_filtrado.comprobante_domicilio` queda sin hidratar o con el valor anterior a la correccion, se puede hacer PATCH preservando:
- `status_filtrado` actual
- `checks` actuales
- `acciones` actuales
- `diagnostico` actual

Solo actualizar `contexto_filtrado` y agregar la accion de correccion correspondiente.

## Evento Centrifugo

```json
{
  "stage": "cierre",
  "status": "en_vistos_buenos",
  "message": "Filtrado cerrado.",
  "detail": "Status, filtrado.status y ruta_solicitud alineados. sin_hallazgos.",
  "progress": { "current": 7, "total": 7, "label": "Cierre" }
}
```

Para `requiere_correccion`:
```json
{
  "stage": "cierre",
  "status": "en_correccion",
  "message": "Filtrado cerrado con hallazgos.",
  "detail": "Descripcion breve de los hallazgos.",
  "progress": { "current": 7, "total": 7, "label": "Cierre" }
}
```
