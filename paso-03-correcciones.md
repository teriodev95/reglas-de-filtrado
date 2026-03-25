# Paso 3 — Correcciones

Contrastar lo leido por OCR contra lo capturado. Corregir directamente cuando hay evidencia clara.

## Actores

| Actor | Rol |
|---|---|
| **Bot de filtrado** | Ejecuta el OCR y detecta la inconsistencia |
| **Agente de IA** | Tiene facultad para aplicar la corrección directamente en el registro de la solicitud en BD |

Cuando el OCR detecta una discrepancia corregible, el agente de IA ejecuta un PATCH inmediato sobre la solicitud con el valor corregido. El flujo continúa usando ya los datos corregidos. No es una sugerencia — es una corrección aplicada.

```
PATCH /api/solicitudes/{solicitud_id}
{
  "campo_corregido": "valor_corregido"
}
```

La corrección se registra también como acción en el arreglo `acciones` de la solicitud (formato descrito abajo), con `estado = "aplicada"` y la evidencia del documento que la respalda.

---

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

Cada corrección genera una entrada en el arreglo `acciones` de la solicitud:

```json
{
  "tipo": "correccion",
  "actor": "agente_ia",
  "campo": "aval.no_servicio",
  "valor_original": "2561307038184",
  "valor_corregido": "256200308144",
  "estado": "aplicada",
  "detalle": "Corregido de 2561307038184 a 256200308144. Comprobante CFE confirma el valor correcto.",
  "evidencia": ["Comprobante CFE: NO DE SERVICIO 256200308144"],
  "timestamp": "ISO_UTC"
}
```

- `actor: "agente_ia"` — siempre que la corrección la aplica el agente
- `estado: "aplicada"` — OCR confirma con claridad → el agente hizo el PATCH
- `estado: "sugerida"` — imagen no permite confirmar → no se modifica el registro, se deja para revisión humana

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
