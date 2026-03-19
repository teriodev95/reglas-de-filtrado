# Criterios Operativos de Filtrado

Reglas aprendidas en operacion real que complementan la matriz y el filtrado autonomo. Cualquier bot o revisor debe respetar estos criterios.

---

## 1. Persona nueva no bloquea solicitud

Si el cliente o aval no existe en la tabla `personas`, **no es un hallazgo bloqueante**. Es simplemente una persona nueva.

Que hacer:

- `c12` o `c13` = `false` (persona_id no asignado)
- `c14`, `c15`, `c16`, `c17` = `true` (sin historial = sin conflictos posibles)
- `c25` = `true` (sin historial negativo)
- `c26` = `true` (sin liquidaciones)
- **no usar `requiere_correccion`** solo por esto
- registrar accion tipo `confirmacion` con detalle "Persona nueva"

Cuando si bloquear:

- cuando un dato no coincide con el documento (nombre, CURP, domicilio)
- cuando hay un conflicto real (morosidad, domicilio compartido, cruce de agencia)
- cuando el aval tiene historial negativo confirmado

---

## 2. Corregir datos documentales directamente

Si el bot detecta que un dato capturado no coincide con el documento (comprobante CFE, INE), debe **corregirlo y registrar la correccion**, no solo sugerirla.

Aplica para:

- `no_servicio` (numero de servicio CFE o contrato de agua)
- `curp` (si la INE muestra un valor diferente al capturado)
- `contrato` (si el comprobante de agua lo muestra con claridad)

Registrar como:

```json
{
  "tipo": "correccion",
  "campo": "aval.no_servicio",
  "estado": "aplicada",
  "detalle": "Corregido de X a Y. Confirmado por comprobante CFE.",
  "evidencia": ["comprobante muestra NO. DE SERVICIO: Y"],
  "timestamp": "ISO_UTC"
}
```

---

## 3. Comprobante de domicilio no requiere nombre del titular

El comprobante de domicilio (CFE, agua, etc.) **puede estar a nombre de otra persona**. Esto es normal cuando:

- la persona renta
- vive con un familiar
- el servicio esta a nombre del propietario

El comprobante prueba que la direccion existe y esta activa, no la propiedad.

**No registrar como hallazgo ni observacion** que el comprobante este a nombre de un tercero.

---

## 4. Que SI es un hallazgo bloqueante

Usar `requiere_correccion` cuando:

| Hallazgo | Check afectado |
|---|---|
| Cliente y aval comparten domicilio (mismo NoServicio o misma direccion en INE) | `r01 = false` |
| Nombre capturado no coincide con INE (apellido faltante, nombre invertido que no se puede resolver) | `c08 = false` o `c09 = false` |
| CURP no coincide con INE y no se puede corregir (formato invalido, datos completamente distintos) | `c10 = false` o `c11 = false` |
| Aval fue cliente moroso confirmado | `c14 = false` |
| Aval avalo a cliente moroso confirmado | `c15 = false` |
| Aval tiene liquidacion especial | `c16 = false` |
| Aval activo en otra agencia/gerencia | `c17 = false` |
| Domicilio excede 3 clientes activos | `c18 = false` |
| Domicilio excede monto maximo | `c19 = false` |
| Domicilio cruza agencia/gerencia | `c20 = false` |
| Aumento mayor a $2,000 | `c21 = false` |
| Nivel no corresponde al historial | `c22 = false` |

---

## 5. Diferencia entre corregible y bloqueante

- **NoServicio incorrecto**: corregible. El bot lo corrige y sigue.
- **CURP ultimo digito diferente**: corregible. El bot usa el valor del INE.
- **Fecha de nacimiento mal capturada**: corregible si el INE y CURP coinciden entre si.
- **Apellido invertido en captura**: corregible si la persona es claramente la misma.
- **Nombre completamente diferente al INE**: bloqueante (`c08/c09 = false`).
- **Domicilio compartido cliente/aval**: bloqueante (`r01 = false`).

---

## 6. Siempre resolver todos los checks

Aunque se encuentre un check bloqueante (ej. `r01 = false` o `c08 = false`), el bot debe **seguir evaluando todos los demas checks**. No dejar ningun check pendiente o en `null` solo porque ya se encontro un hallazgo.

Razon:

- El revisor necesita ver el panorama completo de la solicitud
- Si solo se muestra el primer hallazgo, el agente corrige ese y al volver a filtrar aparece otro
- Resolver todo de una vez ahorra ciclos de correccion

Regla:

- recorrer siempre los 26 checks + r01 sin importar si alguno ya fallo
- `null` solo es aceptable con justificacion tecnica (c06/c07 si no es agua, c23 si no hay historial de liquidaciones)
- nunca dejar `null` por "ya encontre un bloqueo, no sigo revisando"

---

## 7. Siempre llenar diagnostico, motivo_rechazo y doc_invalido_detalle

Al guardar el filtrado, estos tres campos son obligatorios:

- `diagnostico`: resumen breve del resultado. Siempre se llena. Incluir nivel, monto, hallazgos principales y correcciones aplicadas.
- `motivo_rechazo`: razon del bloqueo cuando `status_filtrado = requiere_correccion`. Si es `sin_hallazgos`, enviar string vacio `""`.
- `doc_invalido_detalle`: detalle cuando hay documentos con datos incorrectos (nombre no coincide con INE, CURP no coincide, etc). Si no hay problemas documentales, enviar string vacio `""`.

Importante: la API no acepta `null` en estos campos. Usar `""` cuando no aplica.

Ejemplo sin_hallazgos:

```json
{
  "diagnostico": "NUEVO $5000. Personas nuevas, documentos validos. Sin hallazgos.",
  "motivo_rechazo": "",
  "doc_invalido_detalle": ""
}
```

Ejemplo requiere_correccion:

```json
{
  "diagnostico": "NUEVO $5000. c08=false: nombre cliente mal capturado. r01=false: mismo NoServicio.",
  "motivo_rechazo": "1) Nombre cliente incorrecto: falta apellido GASPARIANO. 2) Cliente y aval comparten NoServicio.",
  "doc_invalido_detalle": "INE cliente muestra GASPARIANO GONZALEZ RODOLFO EMILIO pero solicitud capturo EMILIO GONZALEZ RODOLFO."
}
```
