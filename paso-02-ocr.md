# Paso 2 — OCR Documental

Descargar y leer los 4 documentos. Extraer los datos que se usaran en los pasos siguientes.

## Documentos a leer

Descargar en paralelo desde `captura.documentos.imagenes`:

| Tipo | Extraer |
|---|---|
| `ine_cliente_frente` | nombres, ap_paterno, ap_materno, CURP, domicilio, fecha_nac, vigencia |
| `ine_aval_frente` | nombres, ap_paterno, ap_materno, CURP, domicilio, fecha_nac, vigencia, tipo de INE |
| `comprobante_domicilio_cliente` | tipo, no_servicio o contrato, titular, direccion, fecha_emision, recencia |
| `comprobante_domicilio_aval` | tipo, no_servicio o contrato, titular, direccion, fecha_emision, recencia |

## Tipo de comprobante

| Tipo | Campo clave |
|---|---|
| `cfe` | `numero_servicio` — `cumple_al_corriente = no_aplica` |
| `agua` | `numero_contrato` — verificar `cumple_al_corriente` por `periodos_vencidos` |

## Recencia

Comprobante valido si fue emitido dentro de los 3 meses anteriores a la fecha de la solicitud.

## Shape a construir por OCR

```json
{
  "tipo_comprobante": "cfe",
  "cumple_recencia": "si",
  "cumple_al_corriente": "no_aplica",
  "numero_contrato": "no_aplica",
  "numero_servicio": "256130703814",
  "fecha_emision_comprobante": "2026-03-02"
}
```

Este bloque va en:
- `contexto_filtrado.cliente.comprobante_domicilio`
- `contexto_filtrado.aval.comprobante_domicilio`

Android no lo construye. El bot siempre debe hidratarlo.

## Casos especiales

- INE "Credencial para Votar Desde el Extranjero" → domicilio en otro pais, anotar
- Comprobante a nombre de tercero → normal, no es hallazgo
- Comprobante ilegible → anotar, puede afectar c01

## Evento Centrifugo

```json
{
  "stage": "ocr_documental",
  "status": "en_filtrado",
  "message": "Documentos leidos.",
  "detail": "INE cliente y aval leidos. Comprobantes extraidos.",
  "progress": { "current": 2, "total": 7, "label": "OCR Documental" }
}
```
