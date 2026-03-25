# Regla Complementaria - Autorizacion de Creditos a Avales

## Uso

Esta regla sirve para decidir si procede un credito para una persona que entra como aval, con base en:

- nivel de referencia
- monto solicitado
- plazo
- semanas pagadas

Por ahora es una regla complementaria. No forma parte todavia de `c01-c33`.

---

## Regla

1. ubicar el nivel
2. ubicar el rango de monto
3. ubicar el plazo (`16`, `21`, `26`)
4. tomar las semanas pagadas reales
5. consultar la celda de la tabla

Decision:

- si la celda es `N/A` → no procede
- si la celda trae un numero:
  - `semanas_pagadas >= semanas_requeridas` → procede
  - `semanas_pagadas < semanas_requeridas` → no procede

---

## Tabla

| Nivel | $2K-$4.9K 16/21/26 | $5K-$7.9K 16/21/26 | $8K-$9.9K 16/21/26 | $10K-$11.9K 16/21/26 | $12K-$20K 16/21/26 |
|---|---|---|---|---|---|
| Nuevo | 10 / 12 / 14 | 11 / 13 / 15 | N/A / N/A / 16 | N/A / N/A / N/A | N/A / N/A / N/A |
| Nobel | 9 / 11 / 13 | 10 / 12 / 14 | N/A / N/A / 15 | N/A / N/A / N/A | N/A / N/A / N/A |
| VIP | 8 / 10 / 12 | 9 / 11 / 13 | N/A / N/A / 14 | N/A / N/A / N/A | N/A / N/A / N/A |
| Premium | 7 / 9 / 11 | 8 / 10 / 12 | N/A / N/A / 13 | N/A / N/A / N/A | N/A / N/A / N/A |
| Leal | 6 / 8 / 10 | 7 / 9 / 11 | N/A / N/A / 12 | N/A / N/A / N/A | N/A / N/A / N/A |
| Diamante | 4 / 6 / 8 | 5 / 7 / 9 | N/A / 8 / 10 | N/A / N/A / 11 | N/A / N/A / 12 |

---

## Salida recomendada

```json
{
  "tabla_credito_aval": {
    "nivel": "LEAL",
    "monto_solicitado": 6000,
    "rango_monto": "5000-7900",
    "plazo_semanas": 21,
    "semanas_requeridas": 9,
    "semanas_pagadas": 11,
    "cumple": true,
    "motivo": null
  }
}
```

Si no cumple:

```json
{
  "tabla_credito_aval": {
    "nivel": "VIP",
    "monto_solicitado": 8500,
    "rango_monto": "8000-9900",
    "plazo_semanas": 26,
    "semanas_requeridas": 14,
    "semanas_pagadas": 11,
    "cumple": false,
    "motivo": "No alcanza las semanas minimas requeridas."
  }
}
```

Si la combinacion no existe:

```json
{
  "tabla_credito_aval": {
    "nivel": "NUEVO",
    "monto_solicitado": 12000,
    "rango_monto": "12000-20000",
    "plazo_semanas": 16,
    "semanas_requeridas": null,
    "semanas_pagadas": 20,
    "cumple": false,
    "motivo": "La combinacion nivel-monto-plazo no esta permitida."
  }
}
```

---

## Nota

Cuando esta regla ya quede estable:

- se puede convertir en check formal
- se puede mover a un servicio dedicado
