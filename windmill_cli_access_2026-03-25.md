# Windmill Access

Fecha: 2026-03-25 UTC

## Instancia

- URL: `https://windmill.terio.dev`
- API base: `https://windmill.terio.dev/api`
- Workspace principal: `admins`
- Versión validada: `CE v1.664.0`

## Acceso web

- Usuario: `admin@windmill.dev`
- Password: `changeme`

Importante:

- El acceso funciona y fue validado por API.
- Conviene entrar y cambiar la contraseña si la instancia se va a usar en serio.

## Token inicial

Token validado:

```text
C3zfSJhAM2AH4ftqvAENUmVesUwWPjJL
```

Notas:

- Este token sirve como `Bearer` para la API.
- Fue obtenido por login y expira el `2026-03-28 04:39 UTC`.
- Si se va a usar más tiempo, generar un token nuevo desde `Account settings -> Tokens`.

## CLI

Requisito local:

```bash
npm install -g windmill-cli
wmill --version
```

Versión pública observada del paquete:

```bash
npm view windmill-cli version
# 1.664.0
```

Configurar el workspace:

```bash
wmill workspace add terio-windmill admins https://windmill.terio.dev
```

Si pide token, usar el token inicial de arriba.

Comandos útiles:

```bash
wmill workspace
wmill workspace switch terio-windmill
wmill workspace whoami
```

## API

Ejemplo para validar identidad:

```bash
curl -H "Authorization: Bearer C3zfSJhAM2AH4ftqvAENUmVesUwWPjJL" \
  https://windmill.terio.dev/api/users/whoami
```

Ejemplo para validar el workspace:

```bash
curl -H "Authorization: Bearer C3zfSJhAM2AH4ftqvAENUmVesUwWPjJL" \
  https://windmill.terio.dev/api/w/admins/users/whoami
```

Ejemplo de respuesta validada:

```json
{
  "workspace_id": "admins",
  "email": "admin@windmill.dev",
  "is_admin": true,
  "is_super_admin": true
}
```

## Recomendación operativa

1. Entrar a la UI.
2. Cambiar password del admin.
3. Crear un token nuevo con nombre claro y expiración adecuada.
4. Guardar ese token en el gestor de secretos del equipo.

## Referencias

- Docs CLI: `https://www.windmill.dev/docs/advanced/cli/workspace-management`
- Docs tokens: `https://www.windmill.dev/docs/core_concepts/user_tokens`
