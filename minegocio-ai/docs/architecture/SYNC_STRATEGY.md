# Estrategia de sincronización offline-first — MiNegocio AI

Versión 0.1 · Fase 0 · Decisión base: [ADR-002](../decisions/ADR-002.md) · Secuencias en
[SEQUENCE_DIAGRAMS.md](SEQUENCE_DIAGRAMS.md) §2–§4

## 1. Objetivos y garantías

| Garantía | Definición verificable |
|---|---|
| G1 Escritura local inmediata | Toda acción del MVP (excepto emitir un comprobante) termina sin red; p95 ≤ 300 ms |
| G2 Sin pérdida | Una operación confirmada localmente llega al servidor tarde o temprano, o queda visible como "requiere atención". Nunca desaparece en silencio |
| G3 Sin duplicados | Reenviar una operación N veces produce el mismo efecto que enviarla una vez |
| G4 Orden causal por dispositivo | Las operaciones de un dispositivo se aplican en el orden en que ocurrieron (`device_seq`) |
| G5 Convergencia | Tras sincronizar, todos los dispositivos de un negocio muestran el mismo estado consolidado |
| G6 Trazabilidad | Cada cambio del servidor se puede rastrear a `op_id`, dispositivo, usuario y hora |

## 2. Modelo: operaciones de dominio, no filas

El dispositivo **no** sincroniza "filas cambiadas". Envía **operaciones de dominio** con intención
explícita, que el servidor valida y aplica con las mismas reglas que una llamada directa a la API.

| `op_type` | Efecto | Tipo de conflicto |
|---|---|---|
| `sale.complete` | Crea venta + líneas + cobros iniciales; el servidor deriva movimientos de kardex | Sin conflicto (inserción con id único) |
| `sale.void` | Anula venta; compensa kardex y cobros | Carrera con otra anulación (idempotente) o con comprobante emitido (regla de dominio) |
| `payment.record` / `payment.void` | Cobro o devolución; abono a fiado | Sin conflicto / idempotente |
| `expense.record` / `expense.void` | Gasto | Sin conflicto |
| `purchase.receive` / `purchase.void` | Compra recibida: kardex + costo promedio | Sin conflicto (los costos se recalculan en orden de llegada) |
| `inventory.adjust` | Delta con motivo (merma, regalo, daño) | Conmutativo, sin conflicto |
| `inventory.count` | Conteo físico: "conté X a la hora T" | Concurrencia con ventas (§5.3) |
| `product.upsert` / `product.archive` | Catálogo | Edición concurrente de campos (§5.4) |
| `customer.upsert` | Cliente | Edición concurrente; posible duplicado por documento |
| `cash.open` / `cash.close` | Sesión de caja del dispositivo | Una caja por dispositivo, sin conflicto entre dispositivos |
| `dashboard.save` | Layout de widgets | Última escritura gana (no financiero) |
| `invoice.request` | Pide emitir comprobante de una venta | El servidor decide; ver §6 |

Contenido de una operación (sobre JSON):

```json
{
  "op_id": "01936b2e-7c1a-7c3e-9a51-6f0d2b8c4e11",
  "device_seq": 1284,
  "op_type": "sale.complete",
  "entity_type": "sale",
  "entity_id": "01936b2e-7c19-7f02-8d3b-2a6c9e0f1b77",
  "occurred_at": "2026-11-19T15:42:07.311-05:00",
  "client_created_at": "2026-11-19T15:42:07.402-05:00",
  "base_version": null,
  "schema_version": 1,
  "payload": { "...": "contrato en API_CONTRACTS.md §5" }
}
```

## 3. Lado dispositivo

### 3.1 Escritura

```
transacción Drift {
  insertar/actualizar tablas de dominio locales (venta, líneas, cobro, movimiento local)
  device_seq := local_counters.device_seq + 1
  insertar en outbox (op_id = uuid7(), device_seq, payload, status='pending')
}
→ la UI muestra el resultado de inmediato
→ se despierta el SyncEngine (si hay red)
```

Al ser una sola transacción, no puede existir una venta local sin su operación pendiente, ni una
operación sin su venta.

### 3.2 Envío (push)

- Lotes de hasta 50 operaciones o 256 KB, **en orden de `device_seq`**.
- Antes de enviar, `status='sending'`. Al arrancar la app, todo `sending` vuelve a `pending`
  (recuperación tras cierre abrupto). Es seguro gracias a la idempotencia del servidor.
- Respuesta por operación: `applied` → `acked` (se guarda el `result`, por ejemplo el id del
  comprobante); `duplicate` → `acked` con el resultado original; `rejected` → `pending_conflicts`
  con mensaje para el usuario; `retry` → se reprograma.
- **Bloqueo por cabeza de cola**: si una operación queda `rejected`, las siguientes del mismo
  dispositivo que dependan de su entidad (mismo `entity_id` o referencia) se retienen, y el resto
  continúa. Ejemplo: si se rechaza `product.upsert`, se retienen las ventas de ese producto nuevo.

### 3.3 Reintentos con *backoff*

| Situación | Política |
|---|---|
| Sin red / *timeout* / 5xx / 429 | Exponencial con *jitter* completo: base 2 s, factor 2, tope 15 min; sin límite de intentos |
| 429 con `Retry-After` | Respetar el valor indicado |
| 401 | Refrescar token una vez; si falla, pedir reingreso **sin perder la outbox** |
| 409 `sync.op_conflict` (mismo `op_id`, distinto hash) | No reintentar; error de integridad que se reporta a observabilidad y se muestra a soporte |
| 422 / regla de dominio | No reintentar; a `pending_conflicts` con acción sugerida |
| 403 dispositivo revocado | Detener la sincronización; mostrar "Este celular fue desconectado del negocio" y conservar los datos para exportación |

Disparadores: cambio de conectividad, app en primer plano, después de cada operación local
(*debounce* 2 s) y tarea periódica con WorkManager cada 15 min (mínimo del sistema operativo) con
restricción de red.

### 3.4 Recepción (pull)

- `GET /v1/sync/changes?since=<seq>&limit=500`: devuelve cambios con `seq > since`, en orden, ya
  filtrados por negocio y permisos (un vendedor no recibe costos si su rol no los ve).
- Se aplican en una transacción Drift por página y se avanza `sync_state.last_seq` **dentro de la
  misma transacción**.
- Los cambios originados por el propio dispositivo (`origin_device_id`) se aplican igual, porque
  traen la versión consolidada (por ejemplo, el stock con las ventas de otros celulares), pero no
  generan nuevas operaciones.
- Si `since` es menor que el mínimo compactado, el servidor responde `410 sync.resync_required` y el
  dispositivo hace una resincronización completa del catálogo y de los saldos (snapshot), sin tocar
  la outbox.

### 3.5 Orden push → pull

Cada ciclo hace **push y luego pull**. Así el dispositivo recibe la consolidación de sus propias
operaciones y de las de los demás en un solo ciclo.

## 4. Lado servidor

### 4.1 Aplicación idempotente

Por cada operación, en **una transacción**:

```
SET LOCAL app.business_id = :business_id_del_token
1. Verificar que el dispositivo esté activo y pertenezca al negocio; verificar permisos del usuario.
2. SELECT sync_events WHERE op_id = :op_id
     existe y mismo payload_hash → devolver result guardado (status 'duplicate')
     existe y distinto hash      → 409 sync.op_conflict
3. Verificar device_seq: si hay hueco (> último + 1), aplicar igual y registrar alerta de hueco;
   si es menor o igual que una secuencia ya aplicada con otro op_id → 409.
4. Despachar al módulo (sales.service.complete_sale(...)), que valida y escribe.
5. Insertar sync_events (status, result) y las filas sync_changes afectadas.
COMMIT
```

Si el paso 4 falla por una regla de dominio, se hace `ROLLBACK` del efecto pero se registra
`sync_events` con `status='rejected'` en una transacción aparte, para responder lo mismo si se
reenvía.

Concurrencia: dos lotes del mismo dispositivo no se procesan en paralelo (bloqueo consultivo
`pg_advisory_xact_lock(hash(device_id))`). Lotes de dispositivos distintos sí van en paralelo, y la
serialización por fila (`SELECT … FOR UPDATE` en `stock_levels`, `invoice_series`) resuelve la
contención.

### 4.2 Change feed

Cada escritura relevante inserta en `sync_changes (seq, entity_type, entity_id, change_type,
entity_version, origin_op_id, origin_device_id)`. El pull lee las entidades actuales a partir de
esos ids (no guarda copias). Varias filas para la misma entidad en una página se reducen a la última.

## 5. Resolución de conflictos por dominio

> **No existe una política universal de "última escritura gana"**. Solo se usa para preferencias no
> financieras.

### 5.1 Ventas, cobros, gastos y compras: hechos append-only

- Son **hechos ocurridos**: se insertan con id propio y no compiten entre sí.
- **Nunca se rechazan por falta de stock** (la mercadería ya se entregó). El stock queda negativo y
  se genera la alerta `stock.negative`.
- El precio usado es el de la línea (`unit_price`), aunque el catálogo haya cambiado mientras el
  dispositivo estaba sin conexión. Se registra `price_drift` si difiere del vigente, para el reporte.
- Se rechazan solo por: dispositivo revocado, usuario sin permiso **en el momento de la operación**,
  datos inválidos (totales no cuadran) o entidad referenciada inexistente que no llegó en el mismo
  lote. Todo rechazo queda visible en "Requiere atención". Nunca se descarta en silencio.

### 5.2 Anulaciones

- `sale.void` sobre una venta ya anulada se trata como idempotente: responde `applied` con el
  resultado de la anulación original.
- Una venta con comprobante **aceptado** no se anula directamente: el servidor responde
  `rejected: billing.credit_note_required` y la app guía a emitir una nota de crédito.
- Anulaciones creadas sin conexión por un vendedor llevan la autorización con PIN del dueño o
  administrador (`void_authorized_by`), validada localmente con el hash sincronizado y verificada
  de nuevo en el servidor.

### 5.3 Inventario

- `inventory.adjust` es un **delta** (+/−) y es conmutativo: dos ajustes concurrentes se suman.
- `inventory.count` ("conté 12 a las 10:05") se convierte en delta en el servidor:
  `delta = contado − (stock del servidor considerando solo movimientos con occurred_at ≤ hora del conteo)`.
  Los movimientos posteriores al conteo, como ventas de otro celular a las 10:07, se conservan
  encima. Si hubo movimientos de otros dispositivos en una ventana de ±10 min, el conteo se marca
  `needs_review` y el dueño ve: "Mientras contabas se vendieron 2 unidades en otro celular. ¿El
  conteo de 12 fue antes o después?".
- Nunca se envía "fijar stock = X" desde el cliente.

### 5.4 Catálogo y clientes (no financieros, editables)

- Control optimista con `base_version` por entidad y **combinación por campo**:
  - Si los campos editados no se superponen, se combinan.
  - Si se superponen: en **precio y costo** prevalece el cambio de un rol superior (dueño >
    administrador > vendedor); a igual rol, el de `occurred_at` más reciente. El valor descartado se
    registra en `audit_logs` y se notifica al autor.
  - En el resto de campos (nombre, categoría), gana el más reciente por `occurred_at`, con registro
    en auditoría.
- Cliente duplicado por documento (dos celulares registran el mismo DNI sin conexión): el segundo
  `customer.upsert` se **fusiona** con el existente. Las ventas del id perdedor se reasignan mediante
  un alias (`customer_aliases`, Fase 2) para no reescribir ventas inmutables.
- Código de barras duplicado entre dos productos nuevos: se acepta el primero y el segundo queda
  `needs_review` ("Este código ya es de 'Gaseosa 500 ml'. ¿Es el mismo producto?").

### 5.5 Preferencias de dashboard

Documento completo por membresía y última escritura gana por `updated_at` del servidor. Es aceptable
porque no es financiero y el usuario ve el resultado de inmediato.

### 5.6 Comprobantes electrónicos

**Autoridad exclusiva del servidor.** El dispositivo solo envía `invoice.request`; la serie, el
número y el estado los asigna el servidor ([INTEGRATION_PLAN](../sunat/INTEGRATION_PLAN.md) §4).
Sin conexión, la venta queda con "comprobante pendiente" y el cliente recibe, si lo pide, una **nota
de venta interna** rotulada "No es comprobante de pago".

## 6. Múltiples dispositivos sin conexión (escenarios definidos)

| # | Escenario | Comportamiento |
|---|---|---|
| E1 | Celular A y B venden la última gaseosa sin conexión | Ambas ventas se aceptan; stock −1; alerta "stock negativo" al dueño; el reporte muestra ambas ventas |
| E2 | A cambia el precio a S/ 3,00 (dueño) y B vende a S/ 2,50 sin conexión | La venta de B vale S/ 2,50 (hecho ocurrido); se marca `price_drift`; el catálogo queda en S/ 3,00 |
| E3 | A (dueño) pone precio S/ 3,00 y B (vendedor) pone S/ 2,80, ambos sin conexión | Prevalece S/ 3,00 por rol; B recibe aviso; queda en auditoría |
| E4 | A anula una venta de B que B aún no sincronizó | Imposible: A no conoce la venta hasta que B sincroniza. Cada anulación referencia una venta que el dispositivo conoce |
| E5 | A y B anulan la misma venta | La primera se aplica; la segunda responde idempotente (`applied`, misma anulación) |
| E6 | B hace un conteo mientras A vende | §5.3: delta calculado a la hora del conteo; revisión si hay solapamiento |
| E7 | A registra cliente DNI 12345678 y B también | Fusión por documento (§5.4) |
| E8 | B pasa 20 días sin conexión | Sigue vendiendo. Al día 30 pide revalidar sesión en línea, sin bloquear el registro de ventas ya iniciadas. Se avisa cuando hay operaciones con más de 24 h sin sincronizar |
| E9 | Se revoca B (celular perdido) | Las operaciones de B anteriores a la revocación (`occurred_at` < `revoked_at`) se aceptan si llegan; las posteriores se rechazan y se notifica al dueño |
| E10 | Reloj de B adelantado 3 horas | El servidor calcula `client_clock_skew_ms` con `client_created_at` y la hora de recepción; si supera 5 min, alerta en la app y el reporte usa `recorded_at` como referencia secundaria. `occurred_at` se conserva tal cual (es la evidencia de cuándo dijo el dispositivo) |
| E11 | Dos dispositivos crean el mismo producto "Pan francés" | Son dos productos distintos (ids distintos); se sugiere fusionarlos ("¿Son el mismo producto?"); la fusión es una operación auditada de catálogo |
| E12 | B queda con número local `D002-000045` y se reinstala la app | La reinstalación registra un **nuevo dispositivo** con otro `device_code`; no se reutiliza la secuencia, así que no hay colisión |

## 7. Monitoreo y trazabilidad

**Métricas** (OpenTelemetry), por negocio y dispositivo:

| Métrica | Umbral de alerta |
|---|---|
| `sync.outbox.depth` (reportada por la app) | > 500 operaciones |
| `sync.outbox.oldest_age` | > 24 h |
| `sync.ops.rejected` / aplicadas | > 1 % diario |
| `sync.ops.duplicate` | Informativa (reintentos normales); un pico indica un problema de red o de app |
| `sync.seq_gap` | Cualquier hueco sin cerrar en 1 h |
| `sync.op_conflict` (409) | Cualquiera: posible defecto |
| `sync.apply.latency` p95 | > 500 ms por operación |
| `sync.clock_skew` | > 5 min |

**En la app**: indicador permanente (✔ sincronizado · ↻ 12 pendientes · ⚠ 1 requiere atención),
pantalla "Estado de sincronización" con pendientes, rechazados y última sincronización, y el
botón "Enviar diagnóstico a soporte" (sin datos personales y con consentimiento).

**En soporte**: búsqueda por `op_id`, por dispositivo y por entidad, con la línea de tiempo
`sync_events → sync_changes → audit_logs`.

## 8. Versionado del protocolo

- `schema_version` por operación. El servidor acepta la versión actual y la anterior (N y N−1)
  durante al menos 90 días.
- La app informa `app_version`. Si el servidor deja de aceptar su versión, responde
  `426 sync.upgrade_required` y la app pide actualizar **sin descartar la outbox**: las operaciones
  se migran localmente al formato nuevo tras la actualización.

## 9. Pruebas de la estrategia

Se detallan en [TEST_PLAN.md](../TEST_PLAN.md) §5. Resumen: reenvío duplicado, reordenamiento,
pérdida de respuestas, cierre de la app entre `sending` y `acked`, particiones prolongadas, N
dispositivos con operaciones aleatorias y verificación de invariantes (stock = Σ kardex, saldo de
cliente = Σ ventas al fiado − Σ abonos, sin duplicados), además de cambios de reloj.
