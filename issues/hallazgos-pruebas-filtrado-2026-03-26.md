# Hallazgos de Filtrado Manual — 2026-03-26

Filtrado manual de 9 solicitudes con PATCH completo al contrato (checks completos, hallazgos, acciones, contexto_filtrado).

> **Actualizado:** segunda pasada con contrato completo verificado — 2026-03-26T19:00Z

---

## Tabla Resumen (9 solicitudes)

| # | ID (corto) | Cliente | Monto | Status | Hallazgos principales |
|---|------------|---------|-------|--------|----------------------|
| 1 | 6da0f999 | CLARA YANET MARTINEZ | $9,000 | **requiere_correccion** | c11: CURP aval DEAB86066111MPLR06 inválida (ambigua, no corregida); c20: NoServ 237150507243 con préstamo activo SANTOS GREGORIO ($5,000) |
| 2 | 37feaa53 | YESSICA JANETH CASTILLO | $2,000 | **sin_hallazgos** | Todo OK (ambas persona_nueva, comprobantes dentro de 3 meses) |
| 3 | 96011c18 | Mariana Elsa Osorio | $5,000 | **requiere_correccion** | c09: nombre aval invertido (CARLOS MONARCA JUAN → JUAN CARLOS SALVADOR MONARCA); no_servicio_aval corregido (2560401012463 → 256040102463). Correcciones aplicadas en fuente. |
| 4 | 4dfbf546 | REYNA VIVIANA XELANO | $5,000 | **sin_hallazgos** | Todo OK (ambas persona_nueva, cliente 20 años confirmado) |
| 5 | a3512c67 | MARGARITA CALDERON | $5,000 | **requiere_correccion** | c20: NoServ 256060806076 con préstamo activo 12.26-002-01gc ($5,000 saldo $6,890); c17: aval activa en mismo préstamo |
| 6 | 64127174 | ENRIQUETA CACHO | $10,000 | **requiere_correccion** | c10: CURP cliente CABR970715MPLCRN06 → corregida a CABE790715MPLCRN06 (año 97→79, letra R→E). Aplicada en fuente. |
| 7 | f46c1ee5 | MARIA DEL CARMEN VARGAS | $4,000 | **sin_hallazgos** | Todo OK. Préstamo activo MCP es el mismo de esta solicitud. Score 100. |
| 8 | add9188b | JONATHAN MORENO | $5,500 | **requiere_correccion** | c11: CURP aval MEOC04020211PLNRS0 inválida (15 chars) → corregida a MEOO040201HPLNRSA0; no_servicio_aval 2370101017202 → 237010107202. Ambos corregidos en fuente. |
| 9 | b3a0bca6 | Reyna Mercedes Texis | $5,000 | **sin_hallazgos** | Todo OK. Cliente persona_nueva, aval con persona_id sin historial previo. |

**Resumen:** 4 sin_hallazgos / 5 requiere_correccion

---

## Lista de Hallazgos Encontrados

### c20 — Domicilio en préstamo activo (2 casos bloqueantes)
| Solicitud | NoServicio | Préstamo activo | Titular activo | Saldo |
|-----------|-----------|-----------------|---------------|-------|
| 6da0f999 | 237150507243 | 06.26-004-11ef | SANTOS GREGORIO SANTIAGO (tercero) | $4,072.87 |
| a3512c67 | 256060806076 | 12.26-002-01gc | MARGARITA CALDERON (misma cliente) | $6,890.62 |

Notas: 64127174 y f46c1ee5 tienen préstamos activos en MCP pero corresponden al mismo préstamo de la solicitud (mismo PrestamoID, mismo agente, misma semana). add9188b tiene préstamo activo en historial cliente pero a NoServicio diferente (no bloquea c20).

### c11 — CURP aval inválida (1 caso bloqueante sin corrección)
| Solicitud | CURP capturada | Problema | Acción |
|-----------|---------------|----------|--------|
| 6da0f999 | DEAB86066111MPLR06 | Formato fecha inválido (066111), prefijo no corresponde a PEREZ ALDAMA | No corregida — INE ambigua por rotación |

### c10/c11 — CURP corregida en fuente (2 casos)
| Solicitud | Campo | CURP capturada | Problema | CURP corregida (aplicada) |
|-----------|-------|---------------|----------|--------------------------|
| 64127174 | curp_cliente | CABR970715MPLCRN06 | Año 97→79, letra R→E (ENRIQUETA) | **CABE790715MPLCRN06** ✓ |
| add9188b | curp_aval | MEOC04020211PLNRS0 | 15 chars, formato inválido | **MEOO040201HPLNRSA0** ✓ |

### c09 — Nombre aval con campos invertidos y corregido (1 caso)
| Solicitud | Nombre en INE | Capturado (incorrecto) | Corregido en fuente |
|-----------|--------------|----------------------|---------------------|
| 96011c18 | SALVADOR (pat) MONARCA (mat) JUAN CARLOS (nombres) | ap_pat=MONARCA, ap_mat=JUAN, nombres=CARLOS | ap_pat=SALVADOR, ap_mat=MONARCA, nombres=JUAN CARLOS ✓ |

CURP SAMJ920308HTLLNN06 valida la corrección: SA=SALVADOR, M=MONARCA, J=JUAN.

### no_servicio corregido en fuente (2 casos)
| Solicitud | Campo | Valor capturado | Valor corregido | Fuente documental |
|-----------|-------|----------------|-----------------|------------------|
| 96011c18 | aval.no_servicio | 2560401012463 (13 dígitos) | 256040102463 (12 dígitos) | Comprobante CFE aval |
| add9188b | aval.no_servicio | 2370101017202 (13 dígitos) | 237010107202 (12 dígitos) | Comprobante CFE aval |

---

## Patrones Observados

1. **Solicitudes duplicadas o prematuras (c20 masivo):** 5 de 9 solicitudes tienen el domicilio ya comprometido en un préstamo activo. Esto sugiere que los agentes están capturando solicitudes sin verificar primero si el cliente/domicilio ya tiene crédito activo. En algunos casos (a3512c67) es literalmente el mismo par cliente-aval con préstamo activo de la semana anterior.

2. **Errores en CURP (3 casos):** Dos tipos de error:
   - Error de tipeo/OCR: dígitos transpuestos o año incorrecto (64127174: 97 vs 79)
   - Formato corrupto: CURP de 17 chars o con caracteres incorrectos (add9188b)
   Ambos son evitables con validación de formato en el formulario de captura.

3. **Nombre del aval con campos invertidos (96011c18):** El sistema no tiene validación que cruce el orden de apellidos con la CURP capturada. Si se hubiera comparado SAMJ con ap_paterno=MONARCA se detectaría el error de inmediato.

4. **Comprobante vencido (f46c1ee5):** El comprobante del aval data de enero 2026 (74 días). El agente aceptó un documento que claramente supera los 90 días. Validación de fecha en captura sería el control preventivo.

5. **no_servicio con typos:** Dos casos con no_servicio capturado incorrectamente (dígito de más en 96011c18, dígitos transpuestos en add9188b). El campo debería tener validación de longitud y cruce contra CFE si es posible.

6. **Persona_nueva no bloquea:** Las 3 solicitudes con ambos persona_nueva (37feaa53, 4dfbf546, b3a0bca6) pasaron correctamente, confirmando que la regla opera bien.

---

## Recomendaciones para el Flujo de Windmill

### Validaciones preventivas en captura
- **Validar formato CURP** (18 chars, regex) antes de guardar — evita los 3 casos de CURP inválida
- **Validar longitud no_servicio** (11-13 dígitos) — evita los 2 typos de no_servicio
- **Mostrar alerta si el domicilio ya tiene préstamo activo** al momento de captura (consulta rápida MCP c20) — evitaría los 5 casos de c20 bloqueante
- **Validar fecha comprobante** en captura — pedir la fecha explícita y bloquear si >90 días

### Mejoras en el flujo de Windmill/filtrado automático
- **Cruzar CURP vs ap_paterno/ap_materno/nombres:** Si los primeros 4 chars de la CURP no corresponden al nombre capturado, marcar como sospechoso.
- **Verificar consistencia nombre-CURP antes de filtrado:** Un check rápido de CURP[0:2] vs primera letra + primera vocal interna de ap_paterno.
- **Alertar en semana de captura si ya existe préstamo activo mismo cliente:** Comparar persona_id o NoServicio antes de guardar la solicitud.

### Observación sobre solicitudes duplicadas
El caso a3512c67 (MARGARITA CALDERON + AMELIA JIMENEZ) es un duplicado exacto del préstamo 12.26-002-01gc que fue otorgado en semana 12/2026. El sistema debería detectar esto automáticamente y rechazar la solicitud en captura, no en filtrado.

### Para el agente
- Verificar el estado del crédito anterior antes de hacer la solicitud
- Solicitar comprobantes recientes (no más de 2 meses para tener margen)
- Confirmar que la CURP del cliente coincide con la del INE antes de capturar
