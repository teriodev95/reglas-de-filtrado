# Matriz de Validacion de Filtrado v2

## Objetivo

Esta matriz define que checks:

- valida Android
- valida el bot o revisor
- pueden venir prevalidados y luego confirmarse
- solo reflejan requerimientos del plan

Debe tomarse como referencia operativa directa para sesiones nuevas.

---

## API y MCP

Usa API cuando el dato ya existe expuesto por backend. Usa MCP cuando la regla aun no tiene servicio dedicado y necesitas consultar BD directo.

### Datos base

- Elysia base URL:
  - `https://elysia.xpress1.cc`
- Elysia API solicitudes:
  - `https://elysia.xpress1.cc/api/solicitudes-app`
- Elysia API historial:
  - `https://elysia.xpress1.cc/api/filtrado-clientes/historial`
- MCP base URL:
  - `http://65.21.188.158:7400`
- MCP API key:
  - `9mYS%hyyFGBg#x3ByAu%v@d@`

### Endpoints API

- Solicitud completa:
  - `GET https://elysia.xpress1.cc/api/solicitudes-app/{id}`
- Historial cliente o aval:
  - `GET https://elysia.xpress1.cc/api/filtrado-clientes/historial/{persona_id}`

### cURL API

```bash
curl --location 'https://elysia.xpress1.cc/api/solicitudes-app/{id}'
```

```bash
curl --location 'https://elysia.xpress1.cc/api/filtrado-clientes/historial/{persona_id}'
```

### Herramientas MCP

- listar herramientas:

```bash
curl --location 'http://65.21.188.158:7400/tools/list' \
  --header 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@'
```

- ejecutar query:

```bash
curl -X POST 'http://65.21.188.158:7400/run_query' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json' \
  -d '{"query":"SELECT * FROM prestamos_v2 LIMIT 5"}'
```

- ver estructura de tabla:

```bash
curl -X POST 'http://65.21.188.158:7400/get_table_details' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json' \
  -d '{"table":"prestamos_v2"}'
```

- vista previa de tabla:

```bash
curl -X POST 'http://65.21.188.158:7400/select_table_preview' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json' \
  -d '{"table":"prestamos_v2","limit":5}'
```

- estructura ligera general:

```bash
curl -X POST 'http://65.21.188.158:7400/list_mariadb_structure' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json'
```

### Tablas que mas se usan

- `solicitudes`
- `tabla_cargos`
- `solicitud_revision_aprobaciones`
- `prestamos_v2`
- `prestamos_dynamic`
- `prestamos_completados`
- `personas`
- `liquidaciones`

---

## Matriz

| Check | Android | Bot/Revisor | Fuente / validacion | Nota |
|---|---|---|---|---|
| `c01_docs_legibles` | Si | Puede confirmar | OCR app / `/ocr/validate-set` | Android lo calcula desde OCR y validacion documental |
| `c02_ine_cliente_vigente` | Si | Puede confirmar | OCR app / `/ocr/validate-document` | Android valida vigencia del INE cliente |
| `c03_ine_aval_vigente` | Si | Puede confirmar | OCR app / `/ocr/validate-document` | Android valida vigencia del INE aval |
| `c04_comprobante_cliente_reciente` | Si | Puede confirmar | OCR app / `/ocr/validate-document` | Android valida antiguedad del comprobante cliente y el agente la puede reconfirmar |
| `c05_comprobante_aval_reciente` | Si | Puede confirmar | OCR app / `/ocr/validate-document` | Android valida antiguedad del comprobante aval y el agente la puede reconfirmar |
| `contexto_filtrado.cliente.comprobante_domicilio` | No | Si | OCR del agente sobre `comprobante_domicilio_cliente` | El agente debe hidratar este bloque estructurado durante el filtrado. Android no lo manda |
| `contexto_filtrado.aval.comprobante_domicilio` | No | Si | OCR del agente sobre `comprobante_domicilio_aval` | El agente debe hidratar este bloque estructurado durante el filtrado. Android no lo manda |
| `contexto_filtrado.cliente.comprobante_domicilio.cumple_al_corriente` | `si` o `no` | Puede confirmar | OCR agente / `periodos_vencidos` | Solo aplica si `contexto_filtrado.cliente.comprobante_domicilio.tipo_comprobante = agua`. Si es `cfe`, debe guardarse `no_aplica` en el campo estructurado y no usar un check separado |
| `contexto_filtrado.aval.comprobante_domicilio.cumple_al_corriente` | `si` o `no` | Puede confirmar | OCR agente / `periodos_vencidos` | Solo aplica si `contexto_filtrado.aval.comprobante_domicilio.tipo_comprobante = agua`. Si es `cfe`, debe guardarse `no_aplica` en el campo estructurado y no usar un check separado |
| `c08_nombre_cliente_coincide` | No | Si | Solicitud + OCR INE cliente | Se compara nombre capturado vs OCR INE cliente |
| `c09_nombre_aval_coincide` | No | Si | Solicitud + OCR INE aval | Se compara nombre capturado vs OCR INE aval |
| `c10_curp_cliente_valido` | No | Si | Solicitud + OCR INE cliente | Validar que la CURP del cliente tenga 18 caracteres, formato correcto y que coincida razonablemente con nombre, sexo y fecha de nacimiento |
| `c11_curp_aval_valido` | No | Si | Solicitud + OCR INE aval | Validar que la CURP del aval tenga 18 caracteres, formato correcto y que coincida razonablemente con nombre, sexo y fecha de nacimiento |
| `c12_persona_id_cliente_asignado` | Si | Puede confirmar | Busqueda persona + confirmacion UI | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el cliente es persona nueva, guardar `persona_nueva`; no bloquear solo por eso |
| `c13_persona_id_aval_asignado` | Si | Puede confirmar | Busqueda persona + confirmacion UI | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el aval es persona nueva, guardar `persona_nueva`; no bloquear solo por eso |
| `c14_aval_no_fue_cliente_moroso` | No | Si | `GET /api/filtrado-clientes/historial/:persona_id_aval` | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el aval es persona nueva, guardar `persona_nueva` |
| `c15_aval_no_avalo_cliente_moroso` | No | Si | MCP `run_query` + historial de clientes avalados | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el aval es persona nueva, guardar `persona_nueva` |
| `c16_aval_no_avalo_liq_especial` | No | Si | MCP `run_query` en `liquidaciones` | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el aval es persona nueva, guardar `persona_nueva` |
| `c17_aval_no_activo_otra_agencia` | No | Si | MCP `run_query` en `prestamos_v2` | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el aval es persona nueva, guardar `persona_nueva` |
| `c18_domicilio_max_3_clientes` | No | Si | MCP `run_query` por `NoServicio` / `contrato` | Requiere conteo real del domicilio en prestamos activos prestamos_v2 |
| `c19_domicilio_max_monto` | No | Si | MCP `run_query` suma saldos del domicilio | Requiere suma de saldo activo + monto nuevo MAXIMO 30,000 PARA DIAMANTE 40,000 |
| `c20_domicilio_no_cruce_en_prestamo_activo` | No | Si | MCP `run_query` en `prestamos_v2` por `NoServicio` + joins a `agencias`, `gerencias`, `sucursales` | Valida que el mismo domicilio no aparezca ya comprometido en otro prestamo activo. Si aparece en cualquier otra agencia, gerencia o sucursal, guardar `false` y documentar donde se encontro |
| `r01_cliente_aval_no_comparten_domicilio` | No | Si | Solicitud + OCR comprobantes + campos de domicilio | Valida que cliente y aval no vivan en el mismo domicilio. En regla general no debe ocurrir; solo puede aceptarse si uno de los dos es propietario y se comprueba con predial o escrituras |
| `c21_aumento_max_2000` | Si | Puede confirmar | Historial cliente + elegibilidad app | Android lo calcula primero. El aumento maximo es de 2,000 con respecto al credito anterior |
| `c22_nivel_valido_por_scores` | Si | Puede confirmar | Historial cliente + elegibilidad app | Android lo calcula primero. NUEVO no requiere historial; NOBEL exige 1 credito con score >= 80; VIP 2; PREMIUM 3; LEAL 4; DIAMANTE ademas requiere acumulado puntual >= 50,000 |
| `c23_no_liquido_con_descuento_y_sube` | No | Si | MCP `run_query` en `liquidaciones` + nivel anterior | Usa `si`, `no`, `no_aplica` o `persona_nueva`. Si no es renovacion o no hay contexto real de subida de nivel, guardar `no_aplica`; si el cliente es persona nueva, puede usarse `persona_nueva` si la politica operativa lo requiere |
| `c24_ultima_semana_respetada` | Si | Puede confirmar | Historial cliente + saldo vs tarifa | Android lo calcula primero. Si el credito activo esta en ultima semana (`saldo < tarifa`), solo puede mantener mismo monto y mismo nivel |
| `c25_score_cliente_aceptable` | No | Si | `GET /api/filtrado-clientes/historial/:persona_id_cliente` | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el cliente es persona nueva, guardar `persona_nueva` |
| `c26_no_liq_especial_cliente` | No | Si | MCP `run_query` en `liquidaciones` del cliente | Usa `si`, `no`, `persona_nueva` o `no_aplica`. Si el cliente es persona nueva, guardar `persona_nueva` |

---

## Regla de uso

- `prevalidacion_app` debe reflejar solo los checks que Android realmente valida
- `resultado_revision` debe consolidar el resultado final de los 33 checks
- `resultado_revision.contexto_filtrado` debe concentrar el contexto derivado y ya no usar el nombre legacy `detalle`
- Android no llena `contexto_filtrado.comprobante_domicilio`; ese bloque lo debe construir el agente durante el filtrado a partir del OCR del comprobante
- el bot debe usar esta matriz para evitar recalcular checks que no le corresponden
- `diagnostico`, `motivo_rechazo` y `doc_invalido_detalle` nunca deben quedar en `null`
- cuando no apliquen:
  - `motivo_rechazo = no_aplica`
  - `doc_invalido_detalle = no_aplica`

## Regla complementaria referenciada

La autorizacion de creditos a avales se documenta aparte en:

- `regla-complementaria-creditos-avales.md`

Esa regla:

- no forma parte todavia de `c01-c33`
- no debe mezclarse aun como check formal
- debe usarse como validacion complementaria cuando el solicitante actual sea una persona que entra por la politica de creditos a avales
