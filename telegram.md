# Telegram — Integración desde Dev

Bot de Telegram para notificar eventos del filtrado y recibir mensajes del operador.

## Credenciales

```
BOT_TOKEN=8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20
CHAT_ID=510139903
```

El `CHAT_ID` es el del operador principal. Todos los mensajes se envían a ese chat.

---

## Enviar mensaje de texto

```bash
curl -s -X POST "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id": "510139903", "text": "Mensaje aqui"}'
```

## Enviar mensaje con Markdown

Usar `parse_mode: "MarkdownV2"` para formato robusto. Los caracteres especiales `. - ( ) ! =` deben escaparse con `\`.

```bash
curl -s -X POST "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "510139903",
    "parse_mode": "MarkdownV2",
    "text": "*Filtrado cerrado*\nSolicitud: `ff644683`\nResultado: sin\\_hallazgos"
  }'
```

Si el mensaje tiene datos dinámicos con caracteres especiales, usar `parse_mode: "HTML"` que es más predecible:

```bash
curl -s -X POST "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "510139903",
    "parse_mode": "HTML",
    "text": "<b>Filtrado cerrado</b>\nSolicitud: <code>ff644683</code>\nResultado: sin_hallazgos"
  }'
```

## Enviar documento (PDF, imagen, etc.)

```bash
curl -s -X POST "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/sendDocument" \
  -F chat_id=510139903 \
  -F document=@/ruta/al/archivo.pdf \
  -F caption="Descripcion del archivo"
```

No usar `-H "Content-Type: application/json"` con `sendDocument` — es multipart form, no JSON.

## Leer mensajes (polling)

```bash
curl -s "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/getUpdates?offset=-5"
```

Devuelve los últimos 5 updates. Para polling continuo usar `offset` creciente:

```bash
# Primer llamado — obtener el update_id del último mensaje
curl -s "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/getUpdates" \
  | python3 -c "import sys,json; updates=json.load(sys.stdin)['result']; print(updates[-1]['update_id'] if updates else 'sin mensajes')"

# Siguiente llamado — solo mensajes nuevos desde ese update_id+1
curl -s "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/getUpdates?offset={update_id+1}"
```

El texto del mensaje llega en `result[].message.text`.

## Verificar que el bot responde

```bash
curl -s "https://api.telegram.org/bot8716479034:AAEt5QvbvWGxrc7fKx-8A2anIQ9ZlCG6Y20/getMe"
```

Devuelve el perfil del bot. Si responde con `"ok": true` las credenciales son válidas.

---

## Mensajes estándar por paso del filtrado

Usar estos formatos para consistencia:

### Paso 1 — Toma
```
<b>Filtrado iniciado</b>
Solicitud: <code>{solicitud_id}</code>
Cliente: {nombre_cliente}
Agencia: {agencia} | Semana: {semana}
```

### Paso 3 — Corrección aplicada
```
<b>Corrección aplicada</b>
Solicitud: <code>{solicitud_id}</code>
Campo: {campo}
Antes: {valor_anterior} → Después: {valor_corregido}
```

### Paso 5 — Hallazgo bloqueante
```
<b>⚠ Hallazgo bloqueante</b>
Solicitud: <code>{solicitud_id}</code>
Check: {check_id}
Detalle: {descripcion}
```

### Paso 7 — Cierre sin hallazgos
```
<b>Filtrado cerrado ✓</b>
Solicitud: <code>{solicitud_id}</code>
Resultado: sin_hallazgos
Status: en_vistos_buenos
```

### Paso 7 — Cierre con hallazgos
```
<b>Filtrado cerrado — requiere corrección</b>
Solicitud: <code>{solicitud_id}</code>
Resultado: requiere_correccion
Motivo: {motivo_rechazo}
```

### Error de API
```
<b>Error en filtrado</b>
Solicitud: <code>{solicitud_id}</code>
Paso: {paso}
Error: {descripcion_error}
```

---

## Errores comunes

| Error | Causa | Solución |
|---|---|---|
| `400 Bad Request: can't parse entities` | Caracteres especiales sin escapar en MarkdownV2 | Cambiar a `parse_mode: "HTML"` |
| `400 Bad Request: chat not found` | `CHAT_ID` incorrecto | Verificar con `getUpdates` — el chat_id llega en `message.chat.id` |
| `401 Unauthorized` | Token inválido o revocado | Verificar token con `getMe` |
| `multipart/form-data` con JSON | Mezclar `-H Content-Type: application/json` con `-F` | Para documentos usar solo `-F`, sin el header JSON |
| Mensaje vacío enviado | `text` en blanco o null | Siempre validar que el texto no sea vacío antes de enviar |

## Limitaciones de la API

- Máximo 4096 caracteres por mensaje de texto
- Máximo 50 MB por documento enviado
- Rate limit: 30 mensajes por segundo al mismo chat (en la práctica no se alcanza en filtrado)
