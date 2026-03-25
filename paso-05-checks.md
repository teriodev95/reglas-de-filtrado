# Paso 5 — Resolucion de Checks

Consolidar todos los checks con la evidencia de los pasos anteriores. En este paso se confirma el resultado; la mayoria ya fue resuelta en pasos 2-4.

> `r01` se resuelve al final del paso 3 como bloqueo inmediato, no aqui.

## Checks y fuentes

| Check | Resuelto en | Fuente |
|---|---|---|
| `r01_cliente_aval_no_comparten_domicilio` | **Paso 3** | Comprobantes OCR (bloqueo inmediato) |
| `c01_docs_legibles` | Paso 2 | OCR |
| `c02_ine_cliente_vigente` | Paso 2 | OCR INE cliente |
| `c03_ine_aval_vigente` | Paso 2 | OCR INE aval |
| `c04_comprobante_cliente_reciente` | Paso 2 | OCR comprobante cliente |
| `c05_comprobante_aval_reciente` | Paso 2 | OCR comprobante aval |
| `c08_nombre_cliente_coincide` | Paso 3 | Captura vs OCR INE cliente |
| `c09_nombre_aval_coincide` | Paso 3 | Captura vs OCR INE aval |
| `c10_curp_cliente_valido` | Paso 3 | Captura vs OCR INE cliente |
| `c11_curp_aval_valido` | Paso 3 | Captura vs OCR INE aval |
| `c12_persona_id_cliente_asignado` | Paso 4A | Busqueda BD |
| `c21_aumento_max_2000` | Paso 4A | Historial cliente |
| `c22_nivel_valido_por_scores` | Paso 4A | Historial cliente |
| `c23_no_liquido_con_descuento_y_sube` | Paso 4A | MCP liquidaciones |
| `c24_ultima_semana_respetada` | Paso 4A | Historial cliente |
| `c25_score_cliente_aceptable` | Paso 4A | Historial API |
| `c26_no_liq_especial_cliente` | Paso 4A | MCP liquidaciones |
| `c13_persona_id_aval_asignado` | Paso 4B | Busqueda BD |
| `c14_aval_no_fue_cliente_moroso` | Paso 4B | Historial API |
| `c15_aval_no_avalo_cliente_moroso` | Paso 4B | MCP prestamos_v2 |
| `c16_aval_no_avalo_liq_especial` | Paso 4B | MCP liquidaciones |
| `c17_aval_no_activo_otra_agencia` | Paso 4B | MCP prestamos_v2 |
| `c18_domicilio_max_3_clientes` | Paso 4C | MCP prestamos_v2 |
| `c19_domicilio_max_monto` | Paso 4C | MCP prestamos_v2 |
| `c20_domicilio_no_cruce_agencia` | Paso 4C | MCP prestamos_v2 |
| `c24_ultima_semana_respetada` | Android / bot confirma | Historial cliente |
| `c25_score_cliente_aceptable` | Bot | Historial API paso 4 |
| `c26_no_liq_especial_cliente` | Bot | MCP liquidaciones |

## Valores permitidos

- Checks generales: `true`, `false`, `null`
- Checks contextuales `c12, c13, c14, c15, c16, c17, c23, c25, c26`: `"si"`, `"no"`, `"no_aplica"`, `"persona_nueva"`
- Nunca usar `"true"` o `"false"` como string en checks contextuales

## Niveles y scores (c22)

| Nivel | Requisito |
|---|---|
| NUEVO | Sin historial requerido |
| NOBEL | 1 credito con score >= 80 |
| VIP | 2 creditos |
| PREMIUM | 3 creditos |
| LEAL | 4 creditos |
| DIAMANTE | 4 creditos + acumulado puntual >= 50,000 |

## Nunca dejar en null

`c08, c09, c10, c11, c12, c13, c14, c15, c16, c17, r01, c21, c22, c24, c25, c26`

## Pueden ser null con justificacion

- `c18, c19, c20` — solo si no se obtuvo no_servicio corregido
- `c23` — solo si no hay historial de liquidaciones

## Regla de persona nueva

Si el cliente no existe en BD (resuelta en paso 4A):
- `c12 = "persona_nueva"`
- `c21, c22, c23, c24 = "no_aplica"` — no aplican sin historial previo
- `c25, c26 = "persona_nueva"`

Si el aval no existe en BD (resuelta en paso 4B):
- `c13 = "persona_nueva"`
- `c14, c15, c16, c17 = "persona_nueva"`

No bloquear por persona nueva.

## Hallazgos bloqueantes

Usar `requiere_correccion` cuando:

| Hallazgo | Check |
|---|---|
| Nombre no coincide con INE sin posibilidad de correccion | `c08/c09 = false` |
| CURP invalida sin posibilidad de correccion | `c10/c11 = false` |
| Aval fue cliente moroso | `c14 = no` |
| Aval avalo cliente moroso | `c15 = no` |
| Aval tiene liquidacion especial | `c16 = no` |
| Aval activo en otra agencia | `c17 = no` |
| Domicilio excede 3 clientes activos | `c18 = false` |
| Domicilio excede monto maximo | `c19 = false` |
| Domicilio cruza agencia | `c20 = false` |
| Aumento mayor a $2,000 | `c21 = false` |
| Nivel no corresponde al historial | `c22 = false` |

## Resolver todos aunque haya bloqueo

Si ya se encontro un hallazgo bloqueante, continuar evaluando el resto. No dejar checks en null por "ya hay un bloqueo". El revisor necesita el panorama completo.

## Regla complementaria — creditos a avales

### Cuando aplica

Cuando el solicitante no tiene historial propio como cliente, pero fue aval de otro cliente que si tiene historial. En ese caso se puede autorizar usando el historial del cliente que avalaron.

### Como leer la tabla

- **Filas** — nivel del cliente que el solicitante avaló (`NIVEL DE CLIENTE AVALADO`)
- **Columnas** — rango del monto de ese préstamo (`PRESTAMO ACTUAL ENTRE`)
- **Sub-columnas** — plazo de ese préstamo en semanas (`16 SEM. / 21 SEM. / 26 SEM.`)
- **Celda** — semanas pagadas mínimas requeridas para que el aval pueda solicitar crédito
- **N/A** — combinación no autorizada, no procede

### Regla de aprobacion

```
semanas_pagadas_por_el_cliente_avalado >= valor_en_celda → procede
```

### Tabla de autorizacion

| Nivel cliente avalado | $2,000–$4,900 | | | $5,000–$7,900 | | | $8,000–$9,900 | | | $10,000–$11,900 | | | $12,000–$20,000 | | |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| | **16s** | **21s** | **26s** | **16s** | **21s** | **26s** | **16s** | **21s** | **26s** | **16s** | **21s** | **26s** | **16s** | **21s** | **26s** |
| Nuevo    | 10 | 12 | 14 | 11 | 13 | 15 | N/A | N/A | 16  | N/A | N/A | N/A | N/A | N/A | N/A |
| Nobel    |  9 | 11 | 13 | 10 | 12 | 14 | N/A | N/A | 15  | N/A | N/A | N/A | N/A | N/A | N/A |
| VIP      |  8 | 10 | 12 |  9 | 11 | 13 | N/A | N/A | 14  | N/A | N/A | N/A | N/A | N/A | N/A |
| Premium  |  7 |  9 | 11 |  8 | 10 | 12 | N/A | N/A | 13  | N/A | N/A | N/A | N/A | N/A | N/A |
| Leal     |  6 |  8 | 10 |  7 |  9 | 11 | N/A | N/A | 12  | N/A | N/A | N/A | N/A | N/A | N/A |
| Diamante |  4 |  6 |  8 |  5 |  7 |  9 | N/A |  8  | 10  | N/A | N/A |  11 | N/A | N/A |  12 |

### Ejemplo de uso

Solicitud NUEVO $4,000 — el solicitante fue aval de un cliente LEAL con préstamo de $3,500 a 21 semanas.

- Fila: Leal
- Columna: $2,000–$4,900
- Sub-columna: 21 sem → valor requerido = **8**
- Si el cliente pagó 8 o más semanas → procede

### Observaciones

- Solo Diamante puede acceder a montos de $8,000–$9,900 en plazo de 21 sem (8 semanas pagadas)
- Montos $10,000–$11,900 y $12,000–$20,000 solo disponibles para Diamante a 26 sem
- Si la celda es N/A en todos los plazos del rango → no aplica la politica para ese nivel/monto

## Evento Centrifugo

```json
{
  "stage": "resolucion_checks",
  "status": "en_filtrado",
  "message": "Checks resueltos.",
  "detail": "25 checks resueltos. Diagnostico: sin_hallazgos.",
  "progress": { "current": 5, "total": 7, "label": "Resolucion de Checks" }
}
```
