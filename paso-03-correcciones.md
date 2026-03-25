# Paso 3 — Correcciones

Contrastar lo leido por OCR contra lo capturado. Corregir directamente cuando hay evidencia clara.

## Que se puede corregir

| Campo | Cuando corregir |
|---|---|
| `curp` | OCR del INE muestra un valor distinto al capturado |
| `no_servicio` | Comprobante muestra un numero distinto o con digitos extra/transpuestos |
| `contrato` | Comprobante de agua muestra el contrato con claridad |
| `nombres` / `ap_paterno` / `ap_materno` | Campos capturados en orden incorrecto, persona claramente identificable |
| `domicilio` del aval | Capturado con la direccion del cliente en lugar de la propia |

## Corregible vs bloqueante

| Caso | Decision |
|---|---|
| NoServicio con digito extra o transpuesto | Corregir, continuar |
| CURP con ultimo digito diferente | Corregir con INE, continuar |
| Nombres en campos invertidos, persona identificable | Corregir, continuar |
| Domicilio del aval copiado del cliente | Corregir con INE/comprobante, continuar |
| Nombre completamente diferente al INE | Bloqueante — `c08/c09 = false` |
| CURP formato invalido o datos completamente distintos | Bloqueante — `c10/c11 = false` |

## Formato de accion

```json
{
  "tipo": "correccion",
  "campo": "aval.no_servicio",
  "estado": "aplicada",
  "detalle": "Corregido de 2561307038184 a 256200308144. Comprobante CFE confirma el valor correcto.",
  "evidencia": ["Comprobante CFE: NO DE SERVICIO 256200308144"],
  "timestamp": "ISO_UTC"
}
```

- `estado: "aplicada"` cuando el OCR confirma con claridad
- `estado: "sugerida"` solo cuando la imagen no permite confirmar con certeza

## Si no hay correcciones

No registrar accion. Continuar a la validacion r01.

## r01 — Bloqueo inmediato por domicilio compartido

Al terminar las correcciones, evaluar r01 antes de continuar al paso 4.

**Condicion de bloqueo** — cualquiera de las siguientes:
- `no_servicio` cliente == `no_servicio` aval (con valores ya corregidos)
- El comprobante de cliente y aval es el mismo archivo o imagen identica

Si se cumple: resolver `r01 = false`, hacer PATCH inmediato con `status_filtrado = requiere_correccion` y **detener el flujo**. No continuar al paso 4.

Si los domicilios son distintos: resolver `r01 = true` y continuar al paso 4.

## Evento Centrifugo

```json
{
  "stage": "correcciones",
  "status": "en_filtrado",
  "message": "Correcciones aplicadas.",
  "detail": "NS cliente corregido. Sin otras correcciones.",
  "progress": { "current": 3, "total": 7, "label": "Correcciones" }
}
```

Si no hubo correcciones: `"detail": "Sin correcciones necesarias."`
