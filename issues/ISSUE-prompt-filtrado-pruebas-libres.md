# Issue: prompt de filtrado y pruebas libres

## Problema

El prompt actual de Windmill no fija con suficiente claridad:

- el contrato exacto de `PATCH /api/solicitudes-app/{id}/filtrado`
- el shape de `resultado_filtrado.checks`
- los valores permitidos por check
- el uso de `info = "pruebas libres"` para detectar solicitudes de prueba
- el flujo para resetear y volver a correr una solicitud de prueba

Eso deja espacio para respuestas incompletas, texto libre ambiguo o escritura parcial del filtrado.

## Cambio esperado

Actualizar el prompt base para que:

- lea `info = "pruebas libres"` en `GET /api/solicitudes-app/{id}`
- pueda ejecutar `POST /api/solicitudes-app/pruebas-libres/{id}/reset` antes de correr
- escriba siempre `resultado_filtrado` con:
  - `checks`
  - `hallazgos`
  - `acciones`
  - `contexto_filtrado`
- nunca mande `diagnostico`, `motivo_rechazo` ni `doc_invalido_detalle` en `null`
- cierre con salida estructurada y no solo texto libre

## Criterio de terminado

- el prompt documenta el flujo de pruebas libres
- el agente puede resetear, correr, evaluar y volver a correr
- el writeback usa el contrato vigente de filtrado
- el resultado final es consistente y fácil de validar contra el UML y la matriz
