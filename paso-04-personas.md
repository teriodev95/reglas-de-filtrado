# Paso 4 — Personas, Historial y Domicilio

Buscar persona_id para cliente y aval, consultar historial si existen en BD, y validar domicilio.

El flujo es **secuencial condicional**: primero cliente, luego aval, luego domicilio.

---

## 4A — Cliente: ¿existe en BD?

Buscar por CURP (usando el valor corregido del paso 3). Si no hay resultado, buscar por nombre + telefono.

```sql
-- Por CURP
SELECT id FROM personas WHERE curp = '{curp_corregida}'

-- Por nombre + telefono (fallback)
SELECT id FROM personas
WHERE UPPER(CONCAT(nombres,' ',apellido_paterno,' ',apellido_materno)) LIKE '%{nombre}%'
LIMIT 20
```

Si hay duplicados con la misma CURP, usar el registro con `created_at` mas temprano.

### Rama A: Cliente = persona nueva

No hay match confiable en BD. Resolver automaticamente sin consultas adicionales:

| Check | Valor |
|---|---|
| `c12_persona_id_cliente_asignado` | `"persona_nueva"` |
| `c21_aumento_max_2000` | `"no_aplica"` — sin prestamo previo |
| `c22_nivel_valido_por_scores` | `"no_aplica"` — nivel NUEVO no requiere historial |
| `c23_no_liquido_con_descuento_y_sube` | `"no_aplica"` — sin historial de liquidaciones |
| `c24_ultima_semana_respetada` | `"no_aplica"` — sin semana previa |
| `c25_score_cliente_aceptable` | `"persona_nueva"` |
| `c26_no_liq_especial_cliente` | `"persona_nueva"` |

Continuar a **4B — Aval**.

### Rama B: Cliente identificado en BD

Asignar `persona_id` al cliente. Resolver `c12 = "si"`.

Consultar historial:

```bash
GET https://elysia.xpress1.cc/api/filtrado-clientes/historial/{persona_id}
```

Devuelve: `score_final`, lista de prestamos, `acumulado_puntual`.

Con el historial resolver (ver diagrama `filtrado-cliente-identificado`):

| Check | Regla |
|---|---|
| `c22_nivel_valido_por_scores` | Nivel de la solicitud corresponde al historial (ver tabla niveles) |
| `c25_score_cliente_aceptable` | `score_final` cumple para el nivel solicitado |
| `c21_aumento_max_2000` | `monto_actual - monto_ultimo_prestamo <= 2000` |
| `c24_ultima_semana_respetada` | Semana de solicitud respeta cierre del ultimo credito |
| `c26_no_liq_especial_cliente` | Sin liquidacion especial en historial (MCP liquidaciones) |
| `c23_no_liquido_con_descuento_y_sube` | Si `c26 = "no"` Y el nivel sube → `c23 = "no"` (bloqueante) |

**Tabla de niveles (c22)**

| Nivel | Requisito |
|---|---|
| NUEVO | Sin historial requerido |
| NOBEL | 1 credito con score >= 80 |
| VIP | 2 creditos |
| PREMIUM | 3 creditos |
| LEAL | 4 creditos |
| DIAMANTE | 4 creditos + acumulado puntual >= $50,000 |

Continuar a **4B — Aval**.

---

## 4B — Aval: ¿existe en BD?

Misma busqueda: CURP corregida → fallback nombre + telefono.

### Rama A: Aval = persona nueva

No hay match. Resolver automaticamente:

| Check | Valor |
|---|---|
| `c13_persona_id_aval_asignado` | `"persona_nueva"` |
| `c14_aval_no_fue_cliente_moroso` | `"persona_nueva"` — sin historial como cliente |
| `c15_aval_no_avalo_cliente_moroso` | `"persona_nueva"` — nunca avalo a nadie |
| `c16_aval_no_avalo_liq_especial` | `"persona_nueva"` — sin liq. especial |
| `c17_aval_no_activo_otra_agencia` | `"persona_nueva"` — no activo en ninguna agencia |

Continuar a **4C — Domicilio**.

### Rama B: Aval identificado en BD

Asignar `persona_id` al aval. Resolver `c13 = "si"`.

Consultar historial del aval (mismo endpoint con su `persona_id`).
Devuelve historial como cliente (si alguna vez lo fue) y como avalador.

Con el historial resolver (ver diagrama `filtrado-aval-identificado`):

| Check | Fuente | Regla |
|---|---|---|
| `c14_aval_no_fue_cliente_moroso` | Historial API | Aval no tiene prestamos con saldo pendiente o mora |
| `c15_aval_no_avalo_cliente_moroso` | MCP `prestamos_v2` | Ninguno de sus avalados tiene saldo pendiente |
| `c16_aval_no_avalo_liq_especial` | MCP `liquidaciones` | Sin liquidacion especial como avalado |
| `c17_aval_no_activo_otra_agencia` | MCP `prestamos_v2` | No tiene credito activo en gerencia distinta a la solicitud |

**Gerencias conocidas:**
- `GERGC` = Capital Xpress (GoCash)
- `GERD` = Dinero Xpress
- `GERDC` = Dec Xpress
- `GERE` = Efectivo Xpress

Continuar a **4C — Domicilio**.

---

## 4C — Domicilio: c18, c19, c20

Usar el `no_servicio` **corregido** del paso 3.

```sql
SELECT COUNT(*) as total, SUM(Saldo) as saldo_total, GROUP_CONCAT(DISTINCT Gerencia) as gerencias
FROM prestamos_v2 WHERE NoServicio = '{no_servicio_corregido}'
```

| Check | Regla |
|---|---|
| `c18_domicilio_max_3_clientes` | `total <= 3` |
| `c19_domicilio_max_monto` | `saldo_total + monto_nuevo <= 30000` (40000 para Diamante) |
| `c20_domicilio_no_cruce_agencia` | Todas las gerencias en resultado == gerencia de la solicitud |

> Si no se obtuvo `no_servicio` corregido → dejar `c18, c19, c20 = null`. No bloquean por si solos.

---

## 4D — Regla complementaria (si aplica)

Solo si la solicitud es por politica de creditos a avales (el solicitante no tiene historial propio pero avalo a alguien).

Consultar la tabla de autorizacion en `paso-05-checks.md`. Verificar que `semanas_pagadas >= valor_requerido`.

---

## Evento Centrifugo

```json
{
  "stage": "validacion_personas",
  "status": "en_filtrado",
  "message": "Personas, historial y domicilio evaluados.",
  "detail": "Cliente: persona_nueva. Aval: identificado (persona_id: 1234). Domicilio: 1 activo, saldo $5,000.",
  "progress": { "current": 4, "total": 7, "label": "Personas y Domicilio" }
}
```
