# Resumen del Repositorio

## Que es

Repositorio de **documentacion operativa** para el sistema de filtrado de solicitudes de credito de `solicitudes-app`. No contiene codigo; solo reglas, matrices y guias que gobiernan como se revisan y aprueban las solicitudes.

---

## Archivos

| Archivo | Contenido |
|---|---|
| `README.md` | Indice general del repositorio y alcance |
| `FILTRADO-AUTONOMO.md` | Guia completa para que un bot ejecute el filtrado de forma autonoma |
| `RUN.md` | Flujo minimo paso a paso para filtrar una solicitud |
| `matriz-validacion-filtrado-v2.md` | Matriz de 26 checks + 1 regla cruzada que define que valida Android y que valida el bot |
| `regla-complementaria-creditos-avales.md` | Tabla de decision para autorizar creditos a personas que entran como avales |

---

## Conceptos clave

### Solicitud

Expediente de credito que pasa por los estados: `capturada` → `en_filtrado` → `en_correccion` o `en_vistos_buenos` → `lista_desembolso` → `desembolsada`. Tambien puede ser `rechazada` o `cancelada`.

### Filtrado

Proceso de revision donde se validan datos del cliente y del aval contra documentos (INE, comprobante de domicilio), bases de datos internas y reglas de negocio. Puede ejecutarlo un bot de forma autonoma.

### Checks

26 validaciones individuales (`c01`-`c26`) mas una regla cruzada (`r01`) que cubren:

- **Documentos** (`c01`-`c07`): legibilidad, vigencia de INE, comprobante reciente, agua al corriente.
- **Identidad** (`c08`-`c13`): coincidencia de nombre, CURP valido, `persona_id` asignado para cliente y aval.
- **Historial del aval** (`c14`-`c17`): que no sea moroso, no haya avalado morosos, sin liquidaciones especiales, sin prestamo activo en otra agencia.
- **Domicilio** (`c18`-`c20`): maximo 3 clientes por domicilio, monto acumulado no excedido, sin cruce de agencia.
- **Regla cruzada** (`r01`): cliente y aval no deben compartir domicilio salvo excepcion documentada.
- **Elegibilidad** (`c21`-`c26`): aumento maximo, nivel valido por scores, sin liquidacion con descuento y subida, ultima semana respetada, score aceptable, sin liquidacion especial del cliente.

### Acciones

Cada decision del bot se registra como una accion con tipo, campo, estado (`aplicada`, `sugerida`, `fallida`, `no_aplica`), detalle, evidencia y timestamp.

### Regla complementaria de creditos a avales

Tabla aparte que determina si un aval puede recibir un credito propio, segun nivel, monto, plazo y semanas pagadas. Aun no forma parte de los checks formales.

---

## Infraestructura referenciada

- **API Elysia** (`https://elysia.xpress1.cc`): backend de solicitudes e historial.
- **MCP** (`http://65.21.188.158:7400`): servidor de consultas directas a base de datos (MariaDB) para cruces operativos.
- **Centrifugo** (`https://centrifugo-api.terio.dev`): notificaciones en tiempo real al canal de cada solicitud.

---

## Contexto operativo

La operacion se organiza en **sucursales** → **gerencias** → **agencias**. Las tablas principales son `solicitudes`, `personas`, `prestamos_v2`, `prestamos_completados`, `liquidaciones` y `tabla_cargos`.
