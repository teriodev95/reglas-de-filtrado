# Pruebas Windmill de Filtrado

## Objetivo

Probar un filtrado manual, contrastarlo con el flujo completo y volver a correr hasta mejorar el proceso en Windmill.

## Inicio

1. Entrar a Windmill y usar el workspace `admins`.
2. Tomar una solicitud de:
   - `GET /api/solicitudes-app/pruebas-libres`
3. Si quieres una corrida limpia:
   - reset total: `POST /api/solicitudes-app/pruebas-libres/reset`
   - reset individual: `POST /api/solicitudes-app/pruebas-libres/{id}/reset`

## Corrida manual

1. Cargar la solicitud:
   - `GET /api/solicitudes-app/{id}`
2. Evaluar documentos, historial, MCP y reglas del repo.
3. Si un dato documental es claro y contradice captura:
   - `PATCH /api/solicitudes-app/{id}`
4. Guardar filtrado:
   - `PATCH /api/solicitudes-app/{id}/filtrado`

## Qué evaluar

- `filtrado.status`
- `filtrado.diagnostico`
- `filtrado.resultado.checks`
- `filtrado.resultado.acciones`
- `filtrado.resultado.contexto_filtrado`
- `ruta_solicitud`

## Contraste

Contrastar siempre contra:

- `diagramas/filtrado-completo.puml`
- `matriz-validacion-filtrado-v2.md`
- `criterios-operativos-filtrado.md`

## Iteración

Si el resultado manual fue mejor que Windmill:

1. identificar qué check o corrección faltó
2. ajustar el prompt o paso de Windmill
3. reiniciar la misma solicitud
4. volver a correr

## Nota

Si `GET /api/solicitudes-app/{id}` trae `info = "pruebas libres"`, la solicitud está lista para este ciclo de prueba y reintento.
