#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${WORKDIR:-/home/dev/reglas-filtrado}"
SOLICITUD_ID="${1:-}"
MODE="${2:-dry-run}"
BASE_URL="${ELYSIA_BASE_URL:-https://elysia.xpress1.cc}"
LOCK_FILE="${LOCK_FILE:-/tmp/reglas-filtrado.lock}"
CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
SCHEMA_FILE="$WORKDIR/filter-job-schema.json"
JOB_DIR="/tmp/reglas-filtrado-job-${SOLICITUD_ID}"
LOG_FILE="${LOG_FILE:-/tmp/reglas-filtrado-runner.log}"
CENTRIFUGO_API_URL="${CENTRIFUGO_API_URL:-https://centrifugo-api.terio.dev/api/publish}"
CENTRIFUGO_API_KEY="${CENTRIFUGO_API_KEY:-9583814acd2717ed9e0b283c6bd904d495dff0b2cd687e6ebeaafe70fc9b3065}"

log() {
  local message="$1"
  printf '[%s] solicitud=%s mode=%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SOLICITUD_ID" "$MODE" "$message" | tee -a "$LOG_FILE" >&2
}

publish_event() {
  local stage="$1"
  local status="$2"
  local message="$3"
  local detail="$4"
  local progress_current="${5:-0}"
  local progress_total="${6:-0}"
  local progress_label="${7:-Seguimiento del agente}"

  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  curl -sS -X POST "$CENTRIFUGO_API_URL" \
    -H 'Content-Type: application/json' \
    -H "X-API-Key: $CENTRIFUGO_API_KEY" \
    -d "$(cat <<JSON
{"channel":"solicitud.${SOLICITUD_ID}","data":{"type":"bot.message","solicitud_id":"${SOLICITUD_ID}","stage":"${stage}","status":"${status}","message":"${message}","detail":"${detail}","progress":{"current":${progress_current},"total":${progress_total},"label":"${progress_label}"},"meta":{"filtered_by":"runner","filtered_at":"${now}"},"timestamp":"${now}"}}
JSON
)" >/dev/null || true
}

if [[ -z "$SOLICITUD_ID" ]]; then
  echo '{"ok":false,"error":"missing_solicitud_id"}'
  exit 2
fi

if [[ "$MODE" != "dry-run" && "$MODE" != "apply" ]]; then
  echo '{"ok":false,"error":"invalid_mode"}'
  exit 2
fi

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo '{"ok":false,"error":"missing_schema"}'
  exit 2
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "busy_lock"
  publish_event "runner_ocupado" "en_filtrado" "Ya hay una revisión en curso" "El worker sigue ocupado con otra solicitud. Espera a que termine." 0 1 "Esperando turno"
  echo '{"ok":false,"error":"busy","message":"another filter job is running"}'
  exit 3
fi

log "runner_started"
publish_event "runner_iniciado" "en_filtrado" "Se inició la revisión automática" "El sistema está preparando la solicitud y descargando los documentos necesarios." 1 4 "Preparar solicitud"

mkdir -p /tmp
rm -rf "$JOB_DIR"
mkdir -p "$JOB_DIR"
PROMPT_FILE="$(mktemp /tmp/reglas-filtrado-prompt.XXXXXX.txt)"
cleanup() {
  rm -f "$PROMPT_FILE"
  rm -rf "$JOB_DIR"
}
trap cleanup EXIT

SOLICITUD_JSON="$JOB_DIR/solicitud.json"
log "download_solicitud"
curl -fsSL "${BASE_URL}/api/solicitudes-app/${SOLICITUD_ID}" -o "$SOLICITUD_JSON"

readarray -t URLS < <(node -e '
const fs = require("fs");
const file = process.argv[1];
const raw = JSON.parse(fs.readFileSync(file, "utf8"));
const data = raw?.data || raw;
const docs = data?.captura?.documentos || {};
console.log(docs?.comprobante_domicilio_cliente || "");
console.log(docs?.comprobante_domicilio_aval || "");
' "$SOLICITUD_JSON")

CLIENTE_URL="${URLS[0]:-}"
AVAL_URL="${URLS[1]:-}"
CLIENTE_IMG=""
AVAL_IMG=""

if [[ -n "$CLIENTE_URL" ]]; then
  CLIENTE_IMG="$JOB_DIR/comprobante_domicilio_cliente.jpg"
  log "download_cliente_comprobante"
  curl -fsSL "$CLIENTE_URL" -o "$CLIENTE_IMG" || CLIENTE_IMG=""
fi

if [[ -n "$AVAL_URL" ]]; then
  AVAL_IMG="$JOB_DIR/comprobante_domicilio_aval.jpg"
  log "download_aval_comprobante"
  curl -fsSL "$AVAL_URL" -o "$AVAL_IMG" || AVAL_IMG=""
fi

publish_event "runner_contexto_listo" "en_filtrado" "Documentos listos para revisión" "La solicitud y los comprobantes disponibles ya fueron preparados para el agente." 2 4 "Preparar documentos"

cat > "$PROMPT_FILE" <<PROMPT
Trabaja solo sobre una solicitud: ${SOLICITUD_ID}
Modo: ${MODE}
Base URL: ${BASE_URL}
Archivo local de la solicitud ya descargado: ${SOLICITUD_JSON}
Comprobante cliente local: ${CLIENTE_IMG:-no_disponible}
Comprobante aval local: ${AVAL_IMG:-no_disponible}

Lee primero estos archivos locales:
- RUN.md
- FILTRADO-AUTONOMO.md
- matriz-validacion-filtrado-v2.md
- regla-complementaria-creditos-avales.md

Objetivo:
- Procesar exactamente una solicitud.
- No inventar reglas.
- No usar SQL.
- Usar la solicitud JSON local ya descargada y las imagenes locales de comprobante cuando existan.
- Puedes usar curl contra Elysia y contra Centrifugo.
- Emitir progreso por Centrifugo siguiendo la seccion "Notificaciones del bot" de FILTRADO-AUTONOMO.md.
- En dry-run no debes modificar nada.
- En apply puedes hacer PATCH solo si el payload cumple el contrato vigente.

Secuencia obligatoria:
1. Leer las reglas locales.
2. Publicar evento inicial en el canal `solicitud.${SOLICITUD_ID}`.
3. Leer el archivo local de la solicitud y usarlo como fuente principal.
4. Revisar visualmente las imagenes locales de comprobante si existen.
5. Hacer GET ${BASE_URL}/api/solicitudes-app/${SOLICITUD_ID} solo para verificar el estado actual antes de parchear.
6. Verificar si falta contexto de comprobante_domicilio o cualquier campo de filtrado que deba resolver el agente.
7. Si falta `contexto_filtrado.*.comprobante_domicilio` y la imagen local existe, debes inferir y construir el bloque estructurado desde la imagen y las reglas.
8. Si en modo dry-run, construir el payload exacto que enviarías pero no hacer PATCH.
9. Si en modo apply, hacer PATCH a /api/solicitudes-app/${SOLICITUD_ID}/filtrado y luego verificar con GET final.
10. Publicar evento final en el canal `solicitud.${SOLICITUD_ID}` con el resultado.
11. Devolver JSON estricto.

Restricciones:
- No procesar mas de una solicitud.
- No tocar endpoints distintos de:
  - GET /api/solicitudes-app/{id}
  - PATCH /api/solicitudes-app/{id}/filtrado
  - POST https://centrifugo-api.terio.dev/api/publish
- Si falta informacion para guardar con seguridad, no hagas PATCH y explica por qué.
- Si la solicitud ya está correcta, no hagas PATCH.
- Si el filtrado ya está cerrado pero solo falta enriquecer `contexto_filtrado.comprobante_domicilio`, sí puedes hacer PATCH en modo apply siempre que preserves status, checks, acciones y diagnostico actuales.
- No cambies checks ni status si el unico ajuste es completar `contexto_filtrado.comprobante_domicilio`.
- No digas que no se puede si la imagen local sí existe; en ese caso debes leerla y resolverla.

Devuelve JSON con esta forma:
{
  "ok": true,
  "solicitud_id": "${SOLICITUD_ID}",
  "mode": "${MODE}",
  "read_url": "${BASE_URL}/api/solicitudes-app/${SOLICITUD_ID}",
  "patch_url": "${BASE_URL}/api/solicitudes-app/${SOLICITUD_ID}/filtrado",
  "needs_patch": true,
  "patch_applied": false,
  "verification_ok": false,
  "summary": "texto corto",
  "actions_taken": ["..."],
  "payload_preview": null,
  "notes": ["..."]
}
PROMPT

cd "$WORKDIR"
log "claude_started"
RESULT_JSON="$("$CLAUDE_BIN" -p \
  --add-dir "$WORKDIR" "$JOB_DIR" \
  --allowedTools Bash Read \
  --permission-mode dontAsk \
  --output-format json \
  --json-schema "$(cat "$SCHEMA_FILE")" \
  < "$PROMPT_FILE" | node -e '
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => { input += chunk; });
process.stdin.on("end", () => {
  const parsed = JSON.parse(input);
  const output = parsed?.structured_output ?? parsed;
  process.stdout.write(JSON.stringify(output));
});
' )"

log "claude_finished"
echo "$RESULT_JSON"
