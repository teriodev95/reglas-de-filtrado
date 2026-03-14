# Plan de Implementacion del Bot

Este archivo solo documenta la implementacion del bot autonomo. No cambia las reglas de filtrado.

## Objetivo

Procesar solicitudes nuevas de forma asincrona desde un servidor Hetzner usando:

- Codex como agente principal
- Claude como fallback

## Arquitectura minima

- `watcher`
  - revisa solicitudes con `status = capturada`
  - toma la solicitud
  - lanza un worker
- `worker-codex`
  - procesa una sola `solicitud_id`
- `worker-claude`
  - fallback si Codex falla

## Flujo

1. detectar solicitud `capturada`
2. tomarla con `filtered_by` y `filtered_at`
3. marcarla `en_filtrado`
4. ejecutar Codex
5. si falla, ejecutar Claude
6. guardar resultado final
7. enviar notificaciones

## Watcher

El watcher corre en bucle y no filtra; solo detecta y dispara workers.

Pseudocodigo:

```txt
while true
  buscar solicitudes capturadas
  tomar solicitud
  lanzar worker-codex
  esperar 30s
```

## Comando del worker Codex

```bash
cat <<EOF | codex exec -C "$REPO" --dangerously-bypass-approvals-and-sandbox
Filtra autonomamente la solicitud ${SOLICITUD_ID}.

Lee y sigue:
- src/solicitudes-app/RUN.md
- src/solicitudes-app/FILTRADO-AUTONOMO.md
- src/solicitudes-app/matriz-validacion-filtrado-v2.md
- src/solicitudes-app/regla-complementaria-creditos-avales.md

Reglas:
- no preguntes
- usa solo el contrato actual de solicitudes-app
- toma la solicitud al inicio con filtered_by y filtered_at
- si ya esta en_filtrado, no la reproceses
- usa API primero y MCP solo si falta evidencia
- resuelve checks con valores planos true, false o null
- registra acciones con tipo, campo, estado, detalle, evidencia y timestamp
- corrige datos documentales si hay evidencia clara
- guarda el resultado final en PATCH /api/solicitudes-app/{id}/filtrado
- envia notificaciones al canal solicitud.{solicitud_id}
- no inventes campos, estados ni checks fuera del contrato
- al final deja un resumen breve de lo resuelto y lo pendiente
EOF
```

## Reglas de operacion

- no usar `tmux` por solicitud
- usar `systemd` para mantener vivo el watcher
- cada worker procesa solo una solicitud
- si la solicitud ya esta `en_filtrado`, no tomarla otra vez
- usar `filtered_at` para detectar solicitudes colgadas

## Siguiente paso sugerido

- crear `watcher.ts`
- crear `worker-codex.sh`
- crear `worker-claude.sh`
- crear servicio `systemd`
