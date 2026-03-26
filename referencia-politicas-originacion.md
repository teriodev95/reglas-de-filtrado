# Referencia de Politicas de Originacion

Resumen operativo derivado del material interno compartido por usuario. Sirve como referencia complementaria a la matriz y al UML para sesiones futuras.

## Objetivo

Separar tres cosas:

- reglas que ya estan reflejadas en el filtrado actual
- reglas que deben documentarse mejor
- reglas que aun no estan modeladas como check formal

## Reglas ya reflejadas en el filtrado actual

Estas politicas ya tienen expresion total o parcial en la matriz, criterios o UML:

- Cliente y aval no deben vivir en el mismo domicilio
  - `r01_cliente_aval_no_comparten_domicilio`
- Limite maximo de 3 creditos en el mismo domicilio
  - `c18_domicilio_max_3_clientes`
- Limite maximo de monto activo por domicilio
  - `c19_domicilio_max_monto`
- El domicilio no debe aparecer comprometido en otro prestamo activo
  - `c20_domicilio_no_cruce_en_prestamo_activo`
- Aumento maximo de monto en renovacion
  - `c21_aumento_max_2000`
- Restricciones por nivel del cliente
  - `c22_nivel_valido_por_scores`
  - `c25_score_cliente_aceptable`
- Restriccion de ultima semana
  - `c24_ultima_semana_respetada`
- Liquidacion con descuento y subida de nivel
  - `c23_no_sube_nivel_si_liquido_con_descuento`
- Liquidacion especial como bloqueo
  - `c26_no_liq_especial_cliente`
  - `c16_aval_no_avalo_liq_especial`
- Aval con historial negativo o actividad incompatible
  - `c14_aval_no_fue_cliente_moroso`
  - `c15_aval_no_avalo_cliente_moroso`
  - `c17_aval_no_activo_otra_agencia`

## Reglas del material que faltan modelar mejor

Estas ya deberian quedar al menos documentadas como pendientes formales:

- Nacionalidad mexicana
- Edad minima y maxima
  - cliente nuevo: 18 a 65
  - aval: 18 a 65
  - personas de 18 a 21 deben comprobar ingresos
  - renovaciones mayores de 65 requieren evaluacion especial
- Actividad economica obligatoria
  - cliente
  - aval
- Capacidad de pago real
  - cliente
  - aval
- Arraigo minimo
  - mas de 6 meses en domicilio actual para cliente y aval
- Aval dentro de la misma zona del agente
- Validacion de documentos aceptados
  - no solo INE
  - licencia
  - constancia de identidad
  - pasaporte
  - cedula profesional
  - recibo de luz
  - telefono
  - predial
  - escrituras cuando aplique
- No apto por fraude, prestanombre o conducta conflictiva
- Cliente puede tener credito y ser aval solo si su capacidad de pago lo soporta
- Avales cruzados
  - no puede avalar a su aval
- Domicilios vetados
- Domicilios no permitidos
  - fraccionamientos cerrados
  - vecindades
  - lugares donde no se pueda entrar libremente
- Regla de espera de 8 semanas entre creditos activos en el mismo domicilio
  - excepcion: clientes diamante
- Cliente nuevo mayor a 3500 requiere garantias
- Renovacion mayor a 5000 requiere nuevo estudio socioeconomico
- En cambio de domicilio en renovacion debe intervenir seguridad

## Reglas que parecen ser de autorizacion, no de filtrado puro

Estas importan, pero no necesariamente deben convertirse en check de filtrado automatico:

- El cliente debe ser asesorado e informado profesionalmente
- Firmas y huellas en toda la documentacion
- Presencia del agente en la entrega
- Entrega solo en domicilio del cliente o aval
- Horarios y dias autorizados de entrega
- Preparacion documental para desembolso
- Protocolos de seguridad en la entrega
- Comunicacion de condiciones de pago, renovacion y liquidacion

## Liquidaciones: interpretacion correcta en BD

La tabla `liquidaciones` usa:

- `tipo = 'ESPECIAL'`
- `tipo = 'CON_DESCUENTO'`

Interpretacion operativa:

- `ESPECIAL`
  - acuerdo por mora o problema prolongado de pago
  - bloquea por si solo en `c26`
  - tambien afecta `c16` si el aval participo en ese prestamo
- `CON_DESCUENTO`
  - pago anticipado o cierre con descuento permitido
  - no equivale a `ESPECIAL`
  - usar para `c23` cuando ademas hay subida de nivel

## Propuesta de pendientes para la matriz

Si se decide crecer la matriz, estos checks nuevos tendrian sentido:

- `c27_cliente_mexicano`
- `c28_edad_cliente_valida`
- `c29_edad_aval_valida`
- `c30_cliente_con_actividad_economica`
- `c31_aval_con_actividad_economica`
- `c32_cliente_con_capacidad_pago`
- `c33_aval_con_capacidad_pago`
- `c34_arraigo_cliente_min_6_meses`
- `c35_arraigo_aval_min_6_meses`
- `c36_aval_en_misma_zona_agente`
- `c37_no_avales_cruzados`
- `c38_domicilio_no_vetado`
- `c39_domicilio_accesible_para_cobranza`
- `c40_cliente_nuevo_mayor_3500_con_garantias`
- `c41_renovacion_mayor_5000_requiere_estudio`

## Notas para futuras sesiones

- No asumir que toda regla de originacion debe convertirse en check automatico.
- Separar siempre:
  - filtrado automatico
  - autorizacion humana
  - seguridad
  - entrega / desembolso
- Cuando una politica dependa de investigacion en campo o juicio operativo, marcarla como pendiente de autorizacion o seguridad, no inventar un check tecnico.
