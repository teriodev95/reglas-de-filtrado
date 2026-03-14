# Filtrado Autonomo

Guia minima para ejecutar el filtrado de `solicitudes-app` sin mezclarla con la matriz de validacion.

## Objetivo

- revisar una `solicitud_id`
- consultar datos faltantes
- decidir `sin_hallazgos`, `con_hallazgos` o `requiere_correccion`
- completar checks que si se puedan resolver
- ejecutar correcciones o asignaciones cuando si haya evidencia suficiente
- guardar evidencia breve y reproducible

## Orden obligatorio

1. Cargar la solicitud por API.
2. Validar cliente y aval con los datos ya guardados.
3. Consultar MCP solo si falta informacion o hay ambiguedad.
4. Resolver primero bloqueos duros.
5. Completar checks que si se puedan cerrar con evidencia.
6. Registrar acciones ejecutadas, sugeridas o fallidas.
7. Guardar el filtrado en la solicitud.

## API base

```bash
curl --location 'https://elysia.xpress1.cc/api/solicitudes-app/{id}'
```

```bash
curl --location 'https://elysia.xpress1.cc/api/filtrado-clientes/historial/{persona_id}'
```

## Notificaciones del bot

El bot debe informar avances durante el filtrado usando un canal fijo por `solicitud_id`.

Credenciales v1:

- endpoint: `https://centrifugo-api.terio.dev/api/publish`
- api key: `9583814acd2717ed9e0b283c6bd904d495dff0b2cd687e6ebeaafe70fc9b3065`

Canal fijo:

- `solicitud.{solicitud_id}`

Ejemplo:

- `solicitud.5c546214-5400-4916-8aa4-5d2df76d358c`

## Contrato fijo de mensaje

```json
{
  "channel": "solicitud.{solicitud_id}",
  "data": {
    "type": "bot.message",
    "solicitud_id": "{solicitud_id}",
    "stage": "inicio_filtrado",
    "status": "en_filtrado",
    "message": "Se inicio el filtrado de la solicitud.",
    "detail": "Se tomo la solicitud y se marcó en_filtrado con filtered_by y filtered_at.",
    "progress": {
      "current": 1,
      "total": 7,
      "label": "Cargar solicitud"
    },
    "meta": {
      "filtered_by": "bot",
      "filtered_at": "2026-03-14T12:00:00.000Z"
    },
    "timestamp": "2026-03-14T12:00:00.000Z"
  }
}
```

## Reglas del mensaje

- `type` siempre debe ser `bot.message`
- `solicitud_id` siempre debe venir
- `channel` siempre debe ser `solicitud.{solicitud_id}`
- `stage` debe ser corto, estable y en `snake_case`
- `status` debe reflejar el estado actual de la solicitud
- `message` debe ser corto y entendible de un vistazo
- `detail` debe explicar el avance de forma concisa pero util
- `progress.current` y `progress.total` deben reflejar el paso real del flujo
- `timestamp` siempre en ISO UTC

## Stages recomendados

- `inicio_filtrado`
- `consulta_historial`
- `consulta_mcp`
- `validacion_checks`
- `correccion_datos`
- `guardado_resultado`
- `fin_filtrado`

## Eventos minimos obligatorios

Enviar al menos estos mensajes:

1. cuando el bot toma la solicitud
2. cuando detecta un bloqueo o hallazgo importante
3. cuando corrige un dato relevante
4. cuando guarda el resultado final

## Ejemplo cURL

```bash
curl -X POST 'https://centrifugo-api.terio.dev/api/publish' \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: 9583814acd2717ed9e0b283c6bd904d495dff0b2cd687e6ebeaafe70fc9b3065' \
  -d '{"channel":"solicitud.{solicitud_id}","data":{"type":"bot.message","solicitud_id":"{solicitud_id}","stage":"inicio_filtrado","status":"en_filtrado","message":"Se inicio el filtrado de la solicitud.","detail":"Se tomo la solicitud y se marcó en_filtrado con filtered_by y filtered_at.","progress":{"current":1,"total":7,"label":"Cargar solicitud"},"meta":{"filtered_by":"bot","filtered_at":"2026-03-14T12:00:00.000Z"},"timestamp":"2026-03-14T12:00:00.000Z"}}'
```

## Status de la solicitud

El campo `status` controla la ruta del expediente. No usar otro campo para eso.

Valores permitidos:

- `capturada`
- `en_filtrado`
- `en_correccion`
- `en_vistos_buenos`
- `lista_desembolso`
- `desembolsada`
- `rechazada`
- `cancelada`

Reglas minimas:

- al crear la solicitud: `capturada`
- si la app ya envio prevalidacion o el bot ya esta revisando: `en_filtrado`
- si el filtrado detecta correccion pendiente: `en_correccion`
- si el filtrado termina sin hallazgos: `en_vistos_buenos`
- si ya quedaron completos los vistos buenos: `lista_desembolso`
- si ya se desembolso: `desembolsada`
- si la solicitud se cierra negativamente: `rechazada`
- si se cierra por duplicado o baja administrativa: `cancelada`

`status_revision` no controla la ruta. Solo describe el resultado puntual de revision.

## Toma de solicitud para filtrado

En cuanto el bot empiece a trabajar una solicitud debe tomarla.

Paso minimo:

1. enviar `filtered_by`
2. enviar `filtered_at`
3. con eso la solicitud debe quedar en `en_filtrado`

Reglas operativas:

- si una solicitud ya esta en `en_filtrado`, no volverla a procesar
- usar `filtered_at` como hora de toma del filtrado
- usar `filtered_by` como responsable actual
- si una solicitud sigue en `en_filtrado` demasiado tiempo, revisar `filtered_at` para detectar si quedo colgada

No usar `updated_at` para esto. No es una referencia confiable de toma de filtrado.

## Contexto operativo

Usar este contexto para interpretar mejor personas, relaciones y zona operativa.

- `prestamos_v2`
  - aqui viven los prestamos activos
- `prestamos_completados`
  - aqui vive el historial de prestamos completados

- `agencias`
  - identificador: `AgenciaID`
  - cada agencia apunta a una gerencia con `GerenciaID`
  - ejemplo real: `AGC001 -> GERC001`

- `gerencias`
  - identificador: `GerenciaID`
  - nombre legado: `deprecated_name`
  - sucursal asociada: `SucursalID`
  - ejemplo real: `GERC001 -> Ger001 -> GERC`

- `sucursales`
  - identificador: `sucursalID`
  - nombre comercial: `nombre`
  - ejemplos reales:
    - `GERC = Capital Xpress`
    - `GERD = Dinero Xpress`
    - `GERDC = Dec Xpress`
    - `GERE = Efectivo Xpress`
    - `GERGC = GoCash`

## Regla de contexto para busqueda de personas

- No asumir que una persona encontrada en otra gerencia o sucursal es la misma.
- Si un candidato aparece en otra zona operativa sin relacion historica con el cliente actual, tratarlo como candidato debil.
- La coincidencia de nombre sola no basta para asignar `persona_id`.

## MCP base

### Herramientas

```bash
curl --location 'http://65.21.188.158:7400/tools/list' \
--header 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@'
```

### Uso minimo

- `get_table_details`: confirmar columnas reales
- `run_query`: cruces operativos

### Consultas base

Buscar solicitud:

```bash
curl -X POST 'http://65.21.188.158:7400/run_query' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json' \
  -d '{"query":"SELECT id, agencia, gerencia, cliente_persona_id, aval_persona_id, cliente_no_servicio, aval_no_servicio, status_revision FROM solicitudes WHERE id = '\''{solicitud_id}'\''"}'
```

Buscar candidato de aval:

```bash
curl -X POST 'http://65.21.188.158:7400/run_query' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json' \
  -d '{"query":"SELECT id, nombres, apellido_paterno, apellido_materno, curp, telefono FROM personas WHERE UPPER(CONCAT(nombres, '\'' '\'', apellido_paterno, '\'' '\'', apellido_materno)) LIKE '\''%{aval_nombre}%'\'' LIMIT 20"}'
```

Validar relacion historica cliente-aval:

```bash
curl -X POST 'http://65.21.188.158:7400/run_query' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json' \
  -d '{"query":"SELECT PrestamoID, cliente_persona_id, aval_persona_id, Agente, Gerencia, Semana, Anio FROM prestamos_v2 WHERE cliente_persona_id = '\''{cliente_persona_id}'\'' AND aval_persona_id = '\''{aval_persona_id}'\''"}'
```

Validar si el candidato pertenece a otra operacion:

```bash
curl -X POST 'http://65.21.188.158:7400/run_query' \
  -H 'x-api-key: 9mYS%hyyFGBg#x3ByAu%v@d@' \
  -H 'Content-Type: application/json' \
  -d '{"query":"SELECT PrestamoID, cliente_persona_id, aval_persona_id, Agente, Gerencia, Semana, Anio FROM prestamos_completados WHERE aval_persona_id = '\''{aval_persona_id}'\'' ORDER BY Anio DESC, Semana DESC"}'
```

## Regla minima para `aval_persona_id`

No asignar automaticamente un `aval_persona_id` por nombre parecido.

Aceptar solo si:

1. nombre coincide de forma fuerte
2. telefono coincide o es consistente
3. existe relacion historica compatible o contexto operativo compatible
4. no hay conflicto historico evidente

Descartar si:

- telefono distinto
- aparece en otra gerencia/agencia no relacionada
- no existe relacion historica con el cliente actual

Si no hay match confiable:

- `c13_persona_id_aval_asignado = false`
- dejar `c14-c17` sin cerrar
- usar `requiere_correccion`

## Regla sobre CURP

- No usar CURP como criterio principal de matching.
- Solo tomarla como apoyo si existe y coincide.
- Si la CURP falta en BD, el filtro debe seguir operando con:
  - nombre apellido paterno y apellido materno
  - telefono
  - relacion historica
  - gerencia/agencia

## Evidencia minima

Guardar siempre:

- `solicitud_id`
- hallazgo principal
- consultas MCP ejecutadas
- candidato descartado, si existe
- regla aplicada

## Acciones obligatorias

Ademas de guardar `checks`, el filtrado debe registrar `acciones`.

Cada accion debe indicar:

- `tipo`
- `campo`
- `estado`
- `detalle`
- `evidencia`
- `timestamp`

Estados esperados:

- `aplicada`
- `sugerida`
- `fallida`
- `no_aplica`

Ejemplos minimos:

- confirmar nombre por OCR
- corregir un check con evidencia nueva
- asignar `persona_id`
- no asignar `persona_id` por falta de match confiable
- marcar un caso como persona nueva

## Correcciones permitidas

Si un dato fue capturado mal en la solicitud, pero el documento permite leerlo con claridad, el filtrado debe corregirlo y documentar la accion.

Se puede corregir directamente:

- `curp`
- `no_servicio`
- `contrato` cuando el comprobante sea de agua

## Regla para CURP

- Si la CURP capturada no coincide con la leida en el INE, corregir el valor usando el dato documental.
- Registrar una accion `correccion` con evidencia del OCR.
- Ajustar el check correspondiente segun el dato corregido.

## Regla para `no_servicio` y `contrato`

- Si el comprobante muestra con claridad el `no_servicio`, corregirlo.
- Si el comprobante es de agua y muestra `contrato`, corregirlo o completarlo.
- Registrar una accion `correccion` con evidencia del OCR o lectura documental.
- Usar el valor corregido para cruces de domicilio y validaciones operativas.

## Checks del bot

Los checks se guardan como `true`, `false` o `null` planos. No usar objetos.

Referencia completa: `matriz-validacion-filtrado-v2.md`

### Nunca dejar en null (el bot siempre puede resolver)

- c08, c09 — nombres vs INE
- c10, c11 — CURP valido
- c12, c13 — persona_id asignado
- c14, c15, c16, c17 — validaciones del aval (historial + liquidaciones + agencia)
- r01 — mismo domicilio
- c21, c22 — monto y nivel
- c24 — ultima semana respetada
- c25, c26 — score y liquidaciones del cliente

### Pueden ser null con justificacion

- c06, c07 — solo aplica si comprobante es de agua
- c18, c19, c20 — solo si no se pudo obtener no_servicio corregido
- c23 — solo si no hay historial de liquidaciones

## Verificacion final

Antes de guardar, el bot debe:

1. Recorrer los 26 checks. Ningun check obligatorio puede quedar `null`.
2. Verificar que `evidencia` sea array de strings en cada accion.
3. Verificar que `detalle` incluya `cliente.persona_id`, `cliente.score_final`, `aval.persona_id` y `tabla_cargos`.
4. Si algo falta, corregirlo antes de enviar el PATCH.
