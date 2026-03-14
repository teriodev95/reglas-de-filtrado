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
| `c04_comprobante_cliente_reciente` | Si | Puede confirmar | OCR app / `/ocr/validate-document` | Android valida antiguedad del comprobante cliente |
| `c05_comprobante_aval_reciente` | Si | Puede confirmar | OCR app / `/ocr/validate-document` | Android valida antiguedad del comprobante aval |
| `c06_comprobante_agua_al_corriente_cliente` | Si | Puede confirmar | OCR app / `periodos_vencidos` | Android valida `periodos_vencidos = 0` si es agua. Se usa cuando no hay CFE y viceversa |
| `c07_comprobante_agua_al_corriente_aval` | Si | Puede confirmar | OCR app / `periodos_vencidos` | Android valida `periodos_vencidos = 0` si es agua. Se usa cuando no hay CFE y viceversa |
| `c08_nombre_cliente_coincide` | No | Si | Solicitud + OCR INE cliente | Se compara nombre capturado vs OCR INE cliente |
| `c09_nombre_aval_coincide` | No | Si | Solicitud + OCR INE aval | Se compara nombre capturado vs OCR INE aval |
| `c10_curp_cliente_valido` | No | Si | Solicitud + OCR INE cliente | Validar que la CURP del cliente tenga 18 caracteres, formato correcto y que coincida razonablemente con nombre, sexo y fecha de nacimiento |
| `c11_curp_aval_valido` | No | Si | Solicitud + OCR INE aval | Validar que la CURP del aval tenga 18 caracteres, formato correcto y que coincida razonablemente con nombre, sexo y fecha de nacimiento |
| `c12_persona_id_cliente_asignado` | Si | Puede confirmar | Busqueda persona + confirmacion UI | Android lo resuelve con sugerencia o seleccion de persona. Tambien debe poder buscar por nombres y apellidos reordenados si OCR los invierte |
| `c13_persona_id_aval_asignado` | Si | Puede confirmar | Busqueda persona + confirmacion UI | Android lo resuelve con sugerencia o seleccion de persona. Tambien debe poder buscar por nombres y apellidos reordenados si OCR los invierte |
| `c14_aval_no_fue_cliente_moroso` | No | Si | `GET /api/filtrado-clientes/historial/:persona_id_aval` | Requiere historial del aval |
| `c15_aval_no_avalo_cliente_moroso` | No | Si | MCP `run_query` + historial de clientes avalados | Requiere cruces por prestamos avalados e historial de clientes avalados |
| `c16_aval_no_avalo_liq_especial` | No | Si | MCP `run_query` en `liquidaciones` | Requiere consulta a liquidaciones ESPECIALES SELECT * from liquidaciones WHERE tipo = 'ESPECIAL' |
| `c17_aval_no_activo_otra_agencia` | No | Si | MCP `run_query` en `prestamos_v2` | Requiere cruce con prestamos activos del aval |
| `c18_domicilio_max_3_clientes` | No | Si | MCP `run_query` por `NoServicio` / `contrato` | Requiere conteo real del domicilio en prestamos activos prestamos_v2 |
| `c19_domicilio_max_monto` | No | Si | MCP `run_query` suma saldos del domicilio | Requiere suma de saldo activo + monto nuevo MAXIMO 30,000 PARA DIAMANTE 40,000 |
| `c20_domicilio_no_cruce_agencia` | No | Si | MCP `run_query` por agencia y gerencia | Requiere cruce de domicilio contra otras agencias o gerencias |
| `r01_cliente_aval_no_comparten_domicilio` | No | Si | Solicitud + OCR comprobantes + campos de domicilio | Valida que cliente y aval no vivan en el mismo domicilio. En regla general no debe ocurrir; solo puede aceptarse si uno de los dos es propietario y se comprueba con predial o escrituras |
| `c21_aumento_max_2000` | Si | Puede confirmar | Historial cliente + elegibilidad app | Android lo calcula primero. El aumento maximo es de 2,000 con respecto al credito anterior |
| `c22_nivel_valido_por_scores` | Si | Puede confirmar | Historial cliente + elegibilidad app | Android lo calcula primero. NUEVO no requiere historial; NOBEL exige 1 credito con score >= 80; VIP 2; PREMIUM 3; LEAL 4; DIAMANTE ademas requiere acumulado puntual >= 50,000 |
| `c23_no_liquido_con_descuento_y_sube` | No | Si | MCP `run_query` en `liquidaciones` + nivel anterior | Si el cliente liquido con descuento, no puede subir de nivel en la siguiente renovacion. Puede mantener o bajar nivel; monto solo si otras reglas lo permiten |
| `c24_ultima_semana_respetada` | Si | Puede confirmar | Historial cliente + saldo vs tarifa | Android lo calcula primero. Si el credito activo esta en ultima semana (`saldo < tarifa`), solo puede mantener mismo monto y mismo nivel |
| `c25_score_cliente_aceptable` | No | Si | `GET /api/filtrado-clientes/historial/:persona_id_cliente` | Requiere historial final del cliente |
| `c26_no_liq_especial_cliente` | No | Si | MCP `run_query` en `liquidaciones` del cliente | Requiere consulta a liquidaciones del cliente |

---

## Regla de uso

- `prevalidacion_app` debe reflejar solo los checks que Android realmente valida
- `resultado_revision` debe consolidar el resultado final de los 33 checks
- el bot debe usar esta matriz para evitar recalcular checks que no le corresponden

## Regla complementaria referenciada

La autorizacion de creditos a avales se documenta aparte en:

- `regla-complementaria-creditos-avales.md`

Esa regla:

- no forma parte todavia de `c01-c33`
- no debe mezclarse aun como check formal
- debe usarse como validacion complementaria cuando el solicitante actual sea una persona que entra por la politica de creditos a avales
