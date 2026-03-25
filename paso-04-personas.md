# Paso 4 — Personas, Historial y Domicilio

Buscar persona_id, consultar historial y validar domicilio. Todo en paralelo.

## Busqueda de persona_id

Buscar en BD por CURP primero. Si no hay resultado, buscar por nombre + telefono.

```bash
# Por CURP
SELECT id, nombres, apellido_paterno, apellido_materno, curp, telefono
FROM personas WHERE curp = '{curp}'

# Por nombre
SELECT id, nombres, apellido_paterno, apellido_materno, curp, telefono
FROM personas
WHERE UPPER(CONCAT(nombres,' ',apellido_paterno,' ',apellido_materno)) LIKE '%{nombre}%'
LIMIT 20
```

### Criterios para aceptar un candidato

Aceptar solo si:
1. Nombre coincide de forma fuerte
2. Telefono coincide o es consistente
3. Existe relacion historica compatible o contexto operativo compatible
4. No hay conflicto historico evidente

Descartar si:
- Telefono distinto sin justificacion
- Aparece en otra gerencia no relacionada
- No existe relacion historica con el cliente actual

### Persona nueva

Si no hay match confiable y la evidencia indica persona nueva:
- `c12 / c13 = persona_nueva`
- `c14, c15, c16, c17 = persona_nueva`
- `c25, c26 = persona_nueva`
- No bloquear solo por esto

### Duplicados en BD

Si aparecen 2 registros con la misma CURP, usar el de `created_at` mas temprano.

## Historial

```bash
GET https://elysia.xpress1.cc/api/filtrado-clientes/historial/{persona_id}
```

Devuelve `score_final` y lista de prestamos. Usar para c14, c15, c16, c17, c24, c25, c26.

## Domicilio — c18, c19, c20

Usar el `no_servicio` **corregido** del paso 3.

```bash
# Conteo y saldo activo en el domicilio
SELECT COUNT(*) as total, SUM(Saldo) as saldo_total, GROUP_CONCAT(DISTINCT Gerencia) as gerencias
FROM prestamos_v2 WHERE NoServicio = '{no_servicio}'
```

| Check | Regla |
|---|---|
| `c18` | `total <= 3` |
| `c19` | `saldo_total + monto_nuevo <= 30000` (40000 para Diamante) |
| `c20` | Todas las gerencias en el resultado deben ser la misma que la solicitud |

## Contexto operativo

- `GERGC = Capital Xpress (GoCash)`
- `GERD = Dinero Xpress`
- `GERDC = Dec Xpress`
- `GERE = Efectivo Xpress`
- No asumir que un candidato en otra gerencia es la misma persona sin relacion historica

## Evento Centrifugo

```json
{
  "stage": "validacion_personas",
  "status": "en_filtrado",
  "message": "Personas, historial y domicilio validados.",
  "detail": "Cliente: persona_nueva. Aval: persona_nueva. Domicilio: 0 activos.",
  "progress": { "current": 4, "total": 7, "label": "Personas y Domicilio" }
}
```
