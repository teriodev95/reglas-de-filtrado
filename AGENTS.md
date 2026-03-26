# Project Instructions for `reglas-filtrado`

This repository documents the current operational rules for autonomous filtering in `solicitudes-app`.

## Scope

- Apply the guidance in this file only when working inside `/home/dev/reglas-filtrado`.
- Prefer the vendored local references in this repo.

## Primary References

- Start from these files:
  - `matriz-validacion-filtrado-v2.md`
  - `criterios-operativos-filtrado.md`
  - `diagramas/filtrado-completo.puml`
  - `referencia-politicas-originacion.md`

## Current Operating Model

- Resolve filtering with the current backend/API contract and MCP queries documented in the repo.
- Use API when backend already exposes the data.
- Use MCP only for direct database checks that are not exposed by API.

## Document Correction Authority

- If captured identity or address-service data does not match the supporting document, the agent has authority to correct the source fields before closing filtering.
- Use `PATCH /api/solicitudes-app/{id}` for direct source corrections.
- This authority applies to:
  - `nombre` / apellidos from INE
  - `curp` from INE
  - `no_servicio` from CFE
  - `contrato` from water bill
- When the document is clear, do not leave these as suggestion-only. Correct them and record the action with evidence in `resultado_filtrado.acciones`.
- If the document is ambiguous, unreadable, or the identity is not defensible, do not force the correction. Leave the case in `requiere_correccion` and explain it in `doc_invalido_detalle`.

## Filtering Expectations

- Always resolve the full filtering set; do not stop at the first blocking finding.
- Do not block a request only because client or aval is `persona_nueva`.
- A mismatch against INE or comprobante is blocking when it cannot be corrected with clear documentary evidence.
- Always populate:
  - `diagnostico`
  - `motivo_rechazo`
  - `doc_invalido_detalle`
  - `resultado_filtrado.checks`
  - `resultado_filtrado.hallazgos`
  - `resultado_filtrado.acciones`
  - `resultado_filtrado.contexto_filtrado`

## Writeback Rules

- Use `PATCH /api/solicitudes-app/{id}/filtrado` to persist the structured filtering result.
- Use flat check keys and values compatible with the backend contract in this repo.
- Register every applied correction or relevant detection as an action with:
  - `tipo`
  - `campo`
  - `estado`
  - `detalle`
  - `evidencia`
  - `timestamp`
