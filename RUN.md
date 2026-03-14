# RUN

Usa este flujo para filtrar una solicitud de forma autonoma.

## Entrada

- `solicitud_id`

## Punto de entrada

- leer: `GET /api/solicitudes-app/{solicitud_id}`
- guardar: `PATCH /api/solicitudes-app/{solicitud_id}/filtrado`

## Orden

1. cargar solicitud
2. si ya esta en `en_filtrado`, no procesarla
3. tomar solicitud enviando `filtered_by` y `filtered_at`
4. validar cliente y aval con API y MCP
5. corregir datos documentales si aplica
6. resolver checks
7. registrar acciones
8. guardar resultado final
9. enviar notificacion de cierre

## Reglas minimas

- `status` controla la ruta
- al tomar la solicitud debe quedar `en_filtrado`
- al cerrar filtrado:
  - `sin_hallazgos` -> `status = en_vistos_buenos`
  - `requiere_correccion` -> `status = en_correccion`
- usar `filtered_at` para detectar colgadas
- `checks` van en `resultado_filtrado.checks`
- cada check solo puede ser `true`, `false` o `null`
- `acciones` deben llevar `tipo`, `campo`, `estado`, `detalle`, `evidencia`, `timestamp`
- despues de guardar, volver a leer la solicitud y verificar que `status`, `filtrado.status` y `ruta_solicitud` queden alineados

## cURL minimo

Tomar solicitud:

```bash
curl -X PATCH 'https://elysia.xpress1.cc/api/solicitudes-app/{solicitud_id}/filtrado' \
  -H 'Content-Type: application/json' \
  -d '{"filtered_by":"bot","filtered_at":"2026-03-14T18:00:00.000Z"}'
```

Guardar resultado:

```bash
curl -X PATCH 'https://elysia.xpress1.cc/api/solicitudes-app/{solicitud_id}/filtrado' \
  -H 'Content-Type: application/json' \
  -d '{"status_filtrado":"sin_hallazgos","filtered_by":"bot","filtered_at":"2026-03-14T18:05:00.000Z","resultado_filtrado":{"checks":{"c08_nombre_cliente_coincide":true},"acciones":[],"meta":{"status_filtrado":"sin_hallazgos","filtered_by":"bot","filtered_at":"2026-03-14T18:05:00.000Z"}}}'
```

## Referencias

- `FILTRADO-AUTONOMO.md`
- `matriz-validacion-filtrado-v2.md`
- `regla-complementaria-creditos-avales.md`
