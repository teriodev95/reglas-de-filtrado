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
RUN_ID="run-$(date +%Y%m%d%H%M%S)-${SOLICITUD_ID}"

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

refresh_solicitud_json() {
  curl -fsSL "${BASE_URL}/api/solicitudes-app/${SOLICITUD_ID}" -o "$SOLICITUD_JSON"
}

persist_agent_state() {
  local stage="$1"
  local run_status="$2"
  local message="$3"
  local detail="$4"
  local progress_current="${5:-0}"
  local progress_total="${6:-0}"
  local progress_label="${7:-Seguimiento del agente}"
  local payload_file="$JOB_DIR/agent-run-patch.json"

  node - "$SOLICITUD_JSON" "$SOLICITUD_ID" "$RUN_ID" "$MODE" "$stage" "$run_status" "$message" "$detail" "$progress_current" "$progress_total" "$progress_label" > "$payload_file" <<'NODE'
const fs = require("fs");

const [
  solicitudJsonPath,
  solicitudId,
  runId,
  mode,
  stage,
  runStatus,
  message,
  detail,
  progressCurrent,
  progressTotal,
  progressLabel,
] = process.argv.slice(2);

const now = new Date().toISOString();
const raw = JSON.parse(fs.readFileSync(solicitudJsonPath, "utf8"));
const data = raw?.data || raw;
const filtrado = data?.filtrado && typeof data.filtrado === "object" ? data.filtrado : {};
const resultado = filtrado?.resultado && typeof filtrado.resultado === "object"
  ? JSON.parse(JSON.stringify(filtrado.resultado))
  : {};
const existingAgentRun = resultado?.agent_run && typeof resultado.agent_run === "object"
  ? resultado.agent_run
  : {};
const existingEvents = Array.isArray(existingAgentRun.events) ? existingAgentRun.events : [];

const event = {
  type: "bot.message",
  solicitud_id: solicitudId,
  stage,
  status: runStatus,
  message,
  detail: detail || null,
  progress: {
    current: Number(progressCurrent) || 0,
    total: Number(progressTotal) || 0,
    label: progressLabel || "Seguimiento del agente",
  },
  meta: {
    filtered_by: filtrado.filtered_by || "runner",
    filtered_at: filtrado.filtered_at || now,
  },
  timestamp: now,
};

const dedupedEvents = [event, ...existingEvents].filter((current, index, array) => {
  const key = `${current.timestamp}:${current.stage}:${current.status}:${current.message}`;
  return array.findIndex((candidate) => `${candidate.timestamp}:${candidate.stage}:${candidate.status}:${candidate.message}` === key) === index;
}).slice(0, 25);

resultado.agent_run = {
  run_id: existingAgentRun.run_id || runId,
  mode,
  status: runStatus,
  started_at: existingAgentRun.started_at || now,
  finished_at: runStatus === "done" || runStatus === "failed" || runStatus === "cancelled" ? now : null,
  current_stage: stage,
  current_message: message,
  events: dedupedEvents,
};

const payload = {
  status_filtrado: filtrado.status || "pendiente",
  filtered_by: filtrado.filtered_by || "runner",
  filtered_at: filtrado.filtered_at || now,
  diagnostico: filtrado.diagnostico || undefined,
  motivo_rechazo: filtrado.motivo_rechazo || "no_aplica",
  doc_invalido_detalle: filtrado.doc_invalido_detalle || "no_aplica",
  resultado_filtrado: resultado,
};

process.stdout.write(JSON.stringify(payload));
NODE

  curl -fsSL -X PATCH "${BASE_URL}/api/solicitudes-app/${SOLICITUD_ID}/filtrado" \
    -H 'Content-Type: application/json' \
    --data-binary @"$payload_file" >/dev/null || true

  refresh_solicitud_json || true
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
refresh_solicitud_json
persist_agent_state "runner_iniciado" "running" "Se inició la revisión automática" "El sistema está preparando la solicitud y descargando los documentos necesarios." 1 4 "Preparar solicitud"

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
persist_agent_state "runner_contexto_listo" "running" "Documentos listos para revisión" "La solicitud y los comprobantes disponibles ya fueron preparados para el agente." 2 4 "Preparar documentos"

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
- Debes publicar al menos estos pasos intermedios por Centrifugo si la corrida continua:
  - \`reglas_cargadas\`
  - \`solicitud_leida\`
  - \`documentos_revisados\`
  - \`payload_validado\`
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
publish_event "analisis_en_curso" "en_filtrado" "El agente está revisando la solicitud" "Se están evaluando las reglas, el contexto y los comprobantes disponibles." 3 4 "Revisar reglas y documentos"
persist_agent_state "analisis_en_curso" "running" "El agente está revisando la solicitud" "Se están evaluando las reglas, el contexto y los comprobantes disponibles." 3 4 "Revisar reglas y documentos"

set +e
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
CLAUDE_EXIT=$?
set -e

log "claude_finished"
if [[ "$CLAUDE_EXIT" -ne 0 ]]; then
  publish_event "runner_fallido" "failed" "La revisión automática terminó con un problema" "Claude no pudo completar la corrida. Revisa el log del runner para más detalle." 4 4 "Finalizar revisión"
  persist_agent_state "runner_fallido" "failed" "La revisión automática terminó con un problema" "Claude no pudo completar la corrida. Revisa el log del runner para más detalle." 4 4 "Finalizar revisión"
  echo '{"ok":false,"error":"claude_failed"}'
  exit 4
fi

FINAL_SUMMARY="$(node -e 'const raw = JSON.parse(process.argv[1]); process.stdout.write(String(raw.summary || "La revisión terminó."));' "$RESULT_JSON")"
publish_event "runner_finalizado" "done" "La revisión automática terminó" "$FINAL_SUMMARY" 4 4 "Finalizar revisión"
persist_agent_state "runner_finalizado" "done" "$FINAL_SUMMARY" "La última actualización quedó guardada en la solicitud." 4 4 "Finalizar revisión"
echo "$RESULT_JSON"
