# Diagramas de secuencia — MiNegocio AI

Versión 0.1 · Fase 0

## 1. Primera venta (onboarding → venta rápida, sin conexión)

```mermaid
sequenceDiagram
  autonumber
  actor R as Rosa (dueña)
  participant App as App (Flutter)
  participant DB as SQLite (Drift)
  participant SE as SyncEngine
  participant API as API

  R->>App: Instala y abre
  App->>R: "Dime qué vendes y te ayudo a organizarlo"
  R->>App: Ingresa celular
  App->>API: POST /v1/auth/otp (requiere red solo la 1.ª vez)
  API-->>R: Código por SMS/WhatsApp
  R->>App: Ingresa código
  App->>API: POST /v1/auth/verify + registro de dispositivo
  API-->>App: tokens + device_code=1
  R->>App: Rubro: "Bodega"
  App->>DB: Crea negocio, local y plantilla de productos sugeridos (transacción + outbox)
  R->>App: Marca 8 productos sugeridos y pone precios
  App->>DB: product.upsert x8 (outbox)
  Note over R,App: A partir de aquí puede no haber red
  R->>App: Toca "Gaseosa 500 ml" (favorito)
  R->>App: Toca "Cobrar S/ 2,50" → "Efectivo exacto"
  App->>DB: Venta D001-000001 + línea + cobro + movimiento de kardex + outbox (1 transacción)
  App-->>R: ✔ "¡Primera venta registrada!" (≤ 300 ms)
  SE-->>SE: Sin red: programa reintento (backoff)
  Note over SE,API: Cuando vuelve la señal
  SE->>API: POST /v1/sync/push [business.create, product.upsert x8, cash.open, sale.complete]
  API-->>SE: applied x11
  SE->>API: GET /v1/sync/changes?since=0
  API-->>SE: cambios consolidados (stock, ids de servidor)
  SE->>DB: Aplica cambios, avanza cursor, outbox → acked
  App-->>R: Indicador ✔ sincronizado
```

## 2. Push idempotente con respuesta perdida

```mermaid
sequenceDiagram
  autonumber
  participant SE as SyncEngine
  participant API as API /sync/push
  participant PG as PostgreSQL

  SE->>API: Lote [op 1284 sale.complete]
  API->>PG: BEGIN · SET LOCAL app.business_id · buscar op_id → no existe
  API->>PG: complete_sale() · INSERT sync_events(applied) · INSERT sync_changes · COMMIT
  API--xSE: Respuesta perdida (corte de señal)
  Note over SE: outbox sigue en 'sending' → al reintentar vuelve a 'pending'
  SE->>API: Reintento (backoff 2 s, 4 s, …) mismo op_id y mismo contenido
  API->>PG: buscar op_id → existe, mismo payload_hash
  API-->>SE: duplicate + result original
  SE->>SE: outbox 1284 → acked (sin segunda venta)
```

## 3. Dos dispositivos sin conexión venden la última unidad

```mermaid
sequenceDiagram
  autonumber
  participant A as Celular A
  participant B as Celular B
  participant API as API
  participant Owner as Dueña (notificación)

  Note over A,B: Stock local de "Leche tarro": 1 en ambos
  A->>A: Vende 1 (stock local 0)
  B->>B: Vende 1 (stock local 0)
  A->>API: push sale.complete (D001-000310)
  API-->>A: applied (stock servidor 0)
  B->>API: push sale.complete (D002-000122)
  API->>API: No se rechaza por stock · kardex −1 → stock −1
  API-->>B: applied + aviso stock.negative
  API-->>Owner: "Leche tarro quedó en −1. Revisa el conteo o registra la compra"
  A->>API: pull → stock −1
  B->>API: pull → stock −1
```

## 4. Conteo físico concurrente con ventas

```mermaid
sequenceDiagram
  autonumber
  participant B as Celular B (conteo)
  participant A as Celular A (ventas)
  participant API as API

  Note over B: 10:05 cuenta 12 unidades (stock local 14)
  A->>API: 10:07 sale.complete (−2) → servidor 12
  B->>API: 10:20 inventory.count {counted: 12, counted_at: 10:05}
  API->>API: stock a las 10:05 = 14 → delta = 12 − 14 = −2
  API->>API: + venta 10:07 (−2) → stock final 10
  API->>API: Hubo movimientos de otro dispositivo en ±10 min → needs_review
  API-->>B: applied (needs_review): "Mientras contabas se vendieron 2 en otro celular. ¿El conteo fue antes o después?"
```

## 5. Emisión de boleta electrónica (con conexión)

```mermaid
sequenceDiagram
  autonumber
  actor C as Carlos
  participant App
  participant API as API billing
  participant PG as PostgreSQL
  participant W as Worker
  participant P as BillingProvider (PSE/OSE)
  participant S as SUNAT

  C->>App: Venta completada → "Emitir boleta"
  App->>API: invoice.request (vía sync o POST /v1/invoices con Idempotency-Key)
  API->>PG: Validar datos tributarios del negocio y del adquirente
  API->>PG: SELECT invoice_series FOR UPDATE → número 1532 · next_number++
  API->>PG: INSERT invoices(status=queued, B001-1532) + invoice_events(requested) + tarea
  API-->>App: 202 {status: queued, serie-número}
  W->>PG: Toma tarea (SKIP LOCKED) → status=submitting
  W->>P: emit(document) con clave de idempotencia = invoice.id
  P->>S: Envío/validación
  S-->>P: Constancia
  P-->>W: aceptado + evidencia
  W->>W: Guarda evidencia en objetos (WORM) y calcula hash
  W->>PG: status=accepted, evidence_* (CHECK exige evidencia) + invoice_events(accepted)
  W->>PG: Tarea de PDF → pdf_key
  App->>API: pull → invoice accepted + URL de PDF
  C->>App: "Compartir por WhatsApp" (intent de Android)
```

## 6. Emisión con proveedor caído o respuesta ambigua

```mermaid
sequenceDiagram
  autonumber
  participant W as Worker
  participant P as BillingProvider
  participant PG as PostgreSQL

  W->>P: emit(B001-1533)
  P--xW: timeout (no sabemos si llegó)
  W->>PG: status=unknown + invoice_events(error) + next_attempt_at (backoff)
  Note over W: NUNCA reenviar a ciegas un comprobante en estado desconocido
  W->>P: get_status(B001-1533)  (consulta antes de reintentar)
  alt El proveedor lo tiene y está aceptado
    P-->>W: aceptado + evidencia
    W->>PG: status=accepted (con evidencia)
  else El proveedor no lo tiene
    P-->>W: no encontrado
    W->>P: emit(B001-1533) con la misma clave de idempotencia
  else Rechazado
    P-->>W: rechazado (código, motivo)
    W->>PG: status=rejected + aviso al usuario con acción ("Corrige el RUC y vuelve a emitir")
  end
```

## 7. Anulación de venta por vendedor (sin conexión, con PIN)

```mermaid
sequenceDiagram
  autonumber
  actor L as Lucía (vendedora)
  actor R as Rosa (dueña)
  participant App
  participant API

  L->>App: Venta D002-000045 → "Anular"
  App->>L: Motivo (lista simple + texto)
  App->>R: "Pide a la dueña que ingrese su PIN"
  R->>App: PIN (verificado contra hash local)
  App->>App: Transacción: venta voided + cobro voided + kardex sale_void + outbox(sale.void, authorized_by=Rosa)
  App-->>L: "Venta anulada. Devuelve S/ 12,00 en efectivo"
  App->>API: push sale.void
  API->>API: Revalida permiso y PIN (hash), verifica que no exista comprobante aceptado
  API-->>App: applied
  API->>API: audit_logs(sale.void, actor=Lucía, authorized_by=Rosa, motivo)
```

## 8. Recepción de compra con costo promedio

```mermaid
sequenceDiagram
  autonumber
  actor R as Rosa
  participant App
  participant DB as SQLite
  participant API

  R->>App: "Llegó mercadería" → proveedor → productos y cantidades → costo por unidad o total
  App->>DB: purchase + items + kardex purchase_receipt + avg_cost local + outbox(purchase.receive)
  App-->>R: "Stock actualizado: Arroz 5 kg ahora 18"
  App->>API: push purchase.receive
  API->>API: Recalcula avg_cost ponderado con stock consolidado (no con el local)
  API-->>App: applied + avg_cost definitivo (pull)
```
