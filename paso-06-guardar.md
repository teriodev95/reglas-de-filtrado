# Paso 6 — Guardar Resultado

Construir el payload y enviarlo via PATCH.

## Endpoint

```bash
PATCH https://elysia.xpress1.cc/api/solicitudes-app/{solicitud_id}/filtrado
```

## Campos del body

```json
{
  "status_filtrado": "sin_hallazgos",
  "filtered_by": "bot",
  "filtered_at": "ISO_UTC",
  "diagnostico": "NUEVO $5000. Personas nuevas. Sin hallazgos.",
  "motivo_rechazo": "no_aplica",
  "doc_invalido_detalle": "no_aplica",
  "resultado_filtrado": {
    "checks": {},
    "acciones": [],
    "meta": {
      "status_filtrado": "sin_hallazgos",
      "filtered_by": "bot",
      "filtered_at": "ISO_UTC"
    },
    "contexto_filtrado": {}
  }
}
```

## status_filtrado y su efecto

| `status_filtrado` | `status` resultante |
|---|---|
| `sin_hallazgos` | `en_vistos_buenos` |
| `requiere_correccion` | `en_correccion` |
| `con_hallazgos` | `en_correccion` |

## diagnostico, motivo_rechazo, doc_invalido_detalle

Siempre se llenan. Nunca quedan en `null`.

Cuando no aplican usar `"no_aplica"`, no string vacio.

Ejemplo sin hallazgos:
```json
{
  "diagnostico": "NUEVO $5000. Personas nuevas. Sin hallazgos.",
  "motivo_rechazo": "no_aplica",
  "doc_invalido_detalle": "no_aplica"
}
```

Ejemplo con hallazgos:
```json
{
  "diagnostico": "NUEVO $5000. r01=false: domicilio compartido. c11=false: CURP aval incorrecta.",
  "motivo_rechazo": "Cliente y aval comparten domicilio. CURP aval no coincide con INE.",
  "doc_invalido_detalle": "CURP capturada FOCF880421... no corresponde a SANDRA FLORES CORONA."
}
```

## Shape minimo de contexto_filtrado

```json
{
  "cliente": {
    "estado_persona": "persona_nueva",
    "persona_id": null,
    "score_final": 0,
    "comprobante_domicilio": {
      "tipo_comprobante": "cfe",
      "cumple_recencia": "si",
      "cumple_al_corriente": "no_aplica",
      "numero_contrato": "no_aplica",
      "numero_servicio": "256130703814",
      "fecha_emision_comprobante": "2026-03-02"
    }
  },
  "aval": {
    "estado_persona": "persona_nueva",
    "persona_id": null,
    "fue_cliente": "no",
    "comprobante_domicilio": {
      "tipo_comprobante": "cfe",
      "cumple_recencia": "si",
      "cumple_al_corriente": "no_aplica",
      "numero_contrato": "no_aplica",
      "numero_servicio": "256200308144",
      "fecha_emision_comprobante": "2026-01-25"
    }
  },
  "tabla_cargos": {
    "id": 10
  }
}
```

## Errores comunes

- `checks` fuera de `resultado_filtrado`
- `"true"` o `"false"` como string en checks contextuales
- `motivo_rechazo` o `doc_invalido_detalle` en `null`
- `evidencia` en acciones como string en lugar de array
- `numero_servicio` en contexto con el valor incorrecto antes de correccion

## Evento Centrifugo

```json
{
  "stage": "guardado",
  "status": "en_vistos_buenos",
  "message": "Resultado guardado.",
  "detail": "PATCH aplicado. sin_hallazgos.",
  "progress": { "current": 6, "total": 7, "label": "Guardar Resultado" }
}
```
