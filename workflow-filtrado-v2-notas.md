# Workflow `filtrado-v2-branching`

## Objetivo de mantenimiento

- Centralizar configuracion sensible en `Setup`
- Mantener una solicitud fija por defecto para pruebas
- Permitir override por payload sin romper pruebas rapidas
- Evitar dependencias de `mcp_api_key` enviado por el cliente

## Solicitud fija de prueba

- `41cd7d00-6def-4aa2-a531-1ff15357aced`

## Contrato esperado del webhook

Body minimo:

```json
{
  "solicitud_id": "uuid-opcional"
}
```

Si no se envia `solicitud_id`, el workflow usa la solicitud fija de prueba.

## Configuracion interna esperada en `Setup`

- `api_base_url = https://elysia.xpress1.cc`
- `mcp_base_url = http://65.21.188.158:7400`
- `mcp_api_key` resuelta internamente
- `telegram_token` resuelto internamente
- `telegram_chat_id` resuelto internamente
- `take_timestamp` y `filtered_at` alineados al mismo ISO UTC

