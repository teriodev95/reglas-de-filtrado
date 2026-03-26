# Evaluación de Consistencia — WM v2 vs Filtrado Manual
**Fecha:** 2026-03-26
**Flujo evaluado:** `f/filtrado/filtrado_claude_v1` (windmill-v2, 10 pasos segmentados)
**Solicitudes:** 9 pruebas libres (mismas del filtrado manual)

---

## Resumen de Consistencia

| # | ID | Cliente | Manual | WM v2 | Resultado |
|---|-----|---------|--------|-------|-----------|
| 1 | 6da0f999 | CLARA YANET MARTINEZ | requiere_correccion | requiere_correccion | ✓ MATCH |
| 2 | 37feaa53 | YESSICA JANETH CASTILLO | sin_hallazgos | sin_hallazgos | ✓ MATCH |
| 3 | 96011c18 | Mariana Elsa Osorio | requiere_correccion | sin_hallazgos | ~ OCR pendiente Android |
| 4 | 4dfbf546 | REYNA VIVIANA XELANO | sin_hallazgos | sin_hallazgos | ✓ MATCH |
| 5 | a3512c67 | MARGARITA CALDERON | requiere_correccion | requiere_correccion | ✓ MATCH |
| 6 | 64127174 | ENRIQUETA CACHO | requiere_correccion | requiere_correccion | ✓ MATCH + WM detectó c20 adicional |
| 7 | f46c1ee5 | MARIA DEL CARMEN VARGAS | sin_hallazgos | requiere_correccion | ! WM correcto — manual incorrecto |
| 8 | add9188b | JONATHAN MORENO | requiere_correccion | requiere_correccion | ✓ MATCH |
| 9 | b3a0bca6 | Reyna Mercedes Texis | sin_hallazgos | sin_hallazgos | ✓ MATCH |

**Score:** 7/9 match directo. 8/9 si se descuenta el caso OCR. WM superó al manual en 1 caso.

---

## Detalle por Discrepancia

### 96011c18 — Mariana Elsa Osorio
**Manual:** requiere_correccion (c09: nombre aval invertido — OCR)
**WM:** sin_hallazgos
**Explicación:** c09 (`nombre_aval_coincide`) es check OCR — WM lo deja como `pendiente_android` por diseño. La discrepancia es ESPERADA y CORRECTA. La corrección del nombre del aval y del no_servicio debe venir del proceso Android.
**Acción pendiente:** Corrección de fuente (aval.ap_paterno/ap_materno/nombres + no_servicio) no se persistió — ver sección API más abajo.

### f46c1ee5 — MARIA DEL CARMEN VARGAS
**Manual:** sin_hallazgos
**WM:** requiere_correccion (c20: NoServicio 237970604570 en préstamo activo 11.26-005-11ef, saldo $4,934.50)
**Explicación:** **El manual estaba equivocado.** La solicitud es semana 13/2026 pero ya existe un préstamo activo 11.26-005-11ef (semana 11/2026) con el mismo cliente MARIA DEL CARMEN VARGAS, mismo monto $4,000. WM detectó correctamente el cruce. El manual confundió el préstamo activo con "el mismo de la solicitud" cuando en realidad es un préstamo de 2 semanas antes.
**Estado correcto:** `requiere_correccion` — c20 bloqueante.

---

## Hallazgos que WM Detectó Correctamente (Resumen)

| ID | Hallazgo WM | Correcto |
|----|------------|----------|
| 6da0f999 | c11 CURP aval DEAB86066111MPLR06 inválida + c20 NoServ 237150507243 en prestamo 06.26-004-11ef | ✓ |
| a3512c67 | c20 NoServ 256060806076 en prestamo 12.26-002-01gc ($6,890.62) | ✓ |
| 64127174 | c10 CURP CABR970715MPLCRN06 inválida + c20 NoServ 238111201613 en prestamo 11.26-00B-07ef ($11,986.75) | ✓ (c20 era nuevo hallazgo) |
| f46c1ee5 | c20 NoServ 237970604570 en prestamo 11.26-005-11ef ($4,934.50) | ✓ (manual estaba equivocado) |
| add9188b | c11 CURP aval MEOC04020211PLNRS0 inválida (15 chars) | ✓ |

---

## Problemas Encontrados en WM v2

### P1 — c21 y c24 siempre null (backend no acepta "no_aplica")

**Síntoma:** `c21_aumento_max_2000` y `c24_ultima_semana_respetada` almacenados como `null` en todos los casos, incluso cuando el evaluar_checks los calcula correctamente como `"no_aplica"`.

**Causa:** El backend acepta `"no_aplica"` para c23 pero lo convierte a `null` para c21 y c24. Problema de schema en el endpoint `PATCH /filtrado`.

**Impacto:** Cosmético — no afecta la lógica de bloqueo. Pero viola el contrato (null ≠ no_aplica).

**Fix propuesto:** Cambiar c21 y c24 a `True` (pasan) cuando no aplica, en lugar de `"no_aplica"`. Alternativa: pedir al equipo de backend que acepte `"no_aplica"` para estos campos.

### P2 — Correcciones de fuente (captura) no se persisten vía API

**Síntoma:** `PATCH /api/solicitudes-app/{id}` con campos `captura.cliente.curp`, `captura.aval.curp`, `captura.aval.no_servicio` devuelve `success: True, updated: []` pero no modifica la base de datos.

**Casos afectados:**
- 64127174: `cli.curp` debería ser `CABE790715MPLCRN06`, persiste `CABR970715MPLCRN06`
- add9188b: `aval.curp` debería ser `MEOO040201HPLNRSA0`, persiste `MEOC04020211PLNRS0`
- add9188b: `aval.no_servicio` debería ser `237010107202`, persiste `2370101017202`
- 96011c18: `aval.ap_paterno/ap_materno/nombres` + `no_servicio` no corregidos

**Impacto:** WM detecta los datos inválidos correctamente (son inválidos en la fuente). Pero el filtrado posterior a la corrección vuelve a marcar como bloqueante aunque el dato haya sido corregido en papel.

**Fix requerido:** El equipo de backend debe habilitar `captura` para actualizaciones vía PATCH, o crear un endpoint específico `/api/solicitudes-app/{id}/correccion`.

### P3 — backend status siempre "con_hallazgos"

**Síntoma:** El campo `filtrado.status` retorna `con_hallazgos` incluso para solicitudes sin hallazgos.

**Causa:** El backend sobrescribe el status al escribir `resultado_filtrado`. El status real se puede leer desde `resultado.acciones[evaluacion].detalle`.

**Impacto:** UI y reportes que lean `filtrado.status` directamente verán siempre `con_hallazgos`, aunque el status real sea `sin_hallazgos`.

**Fix requerido:** Backend debe respetar el campo `status` enviado en el PATCH de filtrado.

---

## Estructura del Flujo v2 Verificada

Los 10 pasos funcionaron correctamente en todos los casos:

```
cargar_solicitud → historial_cliente → historial_aval →
mcp_prestamos_cliente → mcp_prestamos_aval →
mcp_liq_cliente → mcp_liq_aval →
evaluar_checks → guardar → cerrar
```

- Tiempo promedio de ejecución: ~10 segundos por solicitud (sin LLM)
- 0 errores de ejecución en las 9 solicitudes
- c01-c09: correctamente `pendiente_android` (OCR delegado)
- c10-c26 + r01: evaluados correctamente con Python puro

---

## Recomendaciones de Seguimiento

1. **Corregir c21/c24**: cambiar `"no_aplica"` a `True` en evaluar_checks para casos persona_nueva/sin_historial, hasta que backend acepte el valor correctamente
2. **Solicitar endpoint de corrección de fuente** al equipo backend: `PATCH /api/solicitudes-app/{id}/captura` o similar
3. **f46c1ee5 requiere nueva evaluación**: la solicitud de MARIA DEL CARMEN VARGAS tiene c20 bloqueante real — debe quedar como `requiere_correccion`
4. **Correcciones manuales pendientes de aplicar** (64127174, add9188b, 96011c18): quedarán como bloqueantes hasta que el endpoint de corrección esté disponible
