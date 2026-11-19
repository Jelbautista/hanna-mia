# Contratos de API — MiNegocio AI

Versión 0.1 · Fase 0 · Borrador. En Fase 1 la fuente de verdad pasa a ser el OpenAPI que genera
FastAPI, verificado en CI contra este documento mediante pruebas de contrato.

## 1. Convenciones

| Aspecto | Regla |
|---|---|
| Base | `https://api.<dominio>/v1` (por definir). Versión en la ruta; cambios incompatibles → `/v2` |
| Formato | JSON UTF-8; `snake_case`; fechas ISO 8601 con zona; ids uuid (v7) |
| Dinero | **Cadena decimal** con 2 decimales (`"10.00"`); precios unitarios hasta 4 (`"2.5000"`); cantidades hasta 3 (`"1.250"`). Nunca número JSON |
| Autenticación | `Authorization: Bearer <access_token>` (JWT de 15 min). Los *claims* incluyen `sub`, `device_id` y `business_id` activo |
| Negocio activo | Lo define el token (`business_id`). Cambiar de negocio implica pedir otro token. El cliente nunca elige el `business_id` en la URL |
| Idempotencia | `POST` no sincronizados exigen `Idempotency-Key` (uuid). Se guarda el resultado por 24 h; la misma clave con otro cuerpo responde 409 |
| Paginación | Por cursor: `?cursor=…&limit=…` → `{items, next_cursor}` |
| Errores | `application/problem+json` (RFC 9457) con `code` estable (§8) |
| Límites | Por usuario, dispositivo e IP; `429` con `Retry-After` |
| Trazabilidad | `X-Request-Id` en cada respuesta; la app envía `X-App-Version` y `X-Device-Id` |

## 2. Identidad (A)

| Método | Ruta | Descripción | Auth |
|---|---|---|---|
| POST | `/auth/otp` | Solicita código `{phone_e164, channel: "sms"\|"whatsapp"}` | Pública, con límite estricto |
| POST | `/auth/verify` | `{phone_e164, code, device: {id, name, platform, app_version}}` → tokens | Pública |
| POST | `/auth/refresh` | Rota el *refresh token* (detecta reutilización → revoca la familia) | Refresh |
| POST | `/auth/logout` | Revoca el dispositivo actual | Bearer |
| GET | `/me` | Usuario, membresías y permisos efectivos | Bearer |
| POST | `/auth/switch-business` | `{business_id}` → nuevo token con ese negocio activo | Bearer |

## 3. Negocio (B) y miembros

| Método | Ruta | Permiso |
|---|---|---|
| POST | `/businesses` | Autenticado (crea negocio + local principal + membresía *owner*) |
| GET / PATCH | `/business` | `business.read` / `business.manage` |
| GET / POST / PATCH | `/establishments` | `business.manage` |
| GET | `/members` · POST `/members/invitations` · PATCH `/members/{id}` | `members.manage` |
| GET | `/devices` · POST `/devices/{id}/revoke` | `members.manage` |
| PUT | `/business/tax-profile` | `business.manage`: RUC, régimen, opciones de facturación |

## 4. Recursos de dominio (lectura y uso en línea)

La app escribe principalmente por `/sync/push` (§5). Estos endpoints sirven al panel web, a
integraciones y a lecturas puntuales; usan **los mismos servicios** que la sincronización.

| Módulo | Endpoints |
|---|---|
| D Catálogo | `GET/POST /products`, `GET/PATCH /products/{id}`, `GET /products/by-barcode/{code}`, `GET/POST /categories` |
| E Compras | `GET/POST /purchases`, `POST /purchases/{id}/void`, `GET/POST /suppliers` |
| F Inventario | `GET /stock?establishment_id=`, `GET /inventory/movements?variant_id=`, `POST /inventory/adjustments`, `POST /inventory/counts` |
| G Ventas | `GET /sales?from=&to=`, `GET /sales/{id}`, `POST /sales` (completa), `POST /sales/{id}/void` |
| H Cobros | `GET/POST /payments`, `POST /payments/{id}/void`, `POST /payments/{id}/reconcile` |
| I Clientes | `GET/POST /customers`, `GET /customers/{id}/statement` (estado de cuenta del fiado) |
| K Finanzas | `POST /cash-sessions`, `POST /cash-sessions/{id}/close`, `GET/POST /expenses`, `GET /reports/{summary\|sales\|margin\|cashflow\|receivables}?from=&to=` |
| L Dashboard | `GET /dashboard/widgets?date=`, `GET/PUT /dashboard/preferences` |
| N Suscripción | `GET /subscription`, `GET /plans`, `POST /subscription/checkout` |

## 5. Sincronización (M)

### 5.1 `POST /sync/push`

```json
{
  "device_id": "0193…",
  "app_version": "1.0.0+12",
  "client_now": "2026-11-19T15:45:00.120-05:00",
  "operations": [
    {
      "op_id": "01936b2e-7c1a-7c3e-9a51-6f0d2b8c4e11",
      "device_seq": 1284,
      "op_type": "sale.complete",
      "entity_type": "sale",
      "entity_id": "01936b2e-7c19-7f02-8d3b-2a6c9e0f1b77",
      "occurred_at": "2026-11-19T15:42:07.311-05:00",
      "client_created_at": "2026-11-19T15:42:07.402-05:00",
      "schema_version": 1,
      "payload": {
        "establishment_id": "0193…",
        "cash_session_id": "0193…",
        "customer_id": null,
        "local_number": "D001-000124",
        "mode": "quick",
        "items": [
          {
            "id": "0193…", "line_no": 1, "variant_id": "0193…",
            "description": "Gaseosa 500 ml", "quantity": "4.000", "unit_price": "2.5000",
            "discount": "0.00", "igv_affectation_code": "10", "tax_rate": "0.1800",
            "line_subtotal": "8.47", "line_tax": "1.53", "line_total": "10.00"
          }
        ],
        "totals": { "subtotal": "8.47", "tax_total": "1.53", "discount_total": "0.00", "total": "10.00" },
        "payments": [
          { "id": "0193…", "method": "cash", "amount": "10.00", "tendered": "20.00", "reference": null }
        ],
        "invoice_request": null
      }
    }
  ]
}
```

Respuesta `200` (siempre por operación, aunque algunas fallen):

```json
{
  "server_now": "2026-11-19T15:45:00.410-05:00",
  "clock_skew_ms": -290,
  "results": [
    { "op_id": "01936b2e-…", "status": "applied",   "result": { "sale_id": "0193…", "warnings": ["stock.negative"] } },
    { "op_id": "01936b2f-…", "status": "duplicate", "result": { "…": "resultado original" } },
    { "op_id": "01936b30-…", "status": "rejected",  "error": { "code": "sale.totals_mismatch", "detail": "…" } },
    { "op_id": "01936b31-…", "status": "retry",     "error": { "code": "server.busy" } }
  ]
}
```

| Código HTTP | Significado |
|---|---|
| 200 | Lote procesado; ver `status` de cada operación |
| 401 | Token vencido |
| 403 `sync.device_revoked` | Dispositivo desconectado del negocio |
| 409 `sync.op_conflict` | Mismo `op_id` con contenido distinto (defecto del cliente) |
| 413 | Lote demasiado grande |
| 426 `sync.upgrade_required` | Versión de la app no soportada |

### 5.2 `GET /sync/changes?since={seq}&limit={n≤500}`

```json
{
  "changes": [
    { "seq": 90211, "entity_type": "product_variant", "entity_id": "0193…", "change_type": "upsert",
      "version": 7, "data": { "sale_price": "3.0000", "…": "…" } },
    { "seq": 90212, "entity_type": "stock_level", "entity_id": "0193…", "change_type": "upsert",
      "data": { "variant_id": "0193…", "establishment_id": "0193…", "quantity": "-1.000" } }
  ],
  "next_since": 90212,
  "has_more": false
}
```

`410 sync.resync_required` → `GET /sync/snapshot` (catálogo, stock, clientes con saldo,
configuración), paginado.

### 5.3 Catálogo de `op_type` (v1)

`business.update`, `establishment.upsert`, `product.upsert`, `product.archive`, `category.upsert`,
`customer.upsert`, `supplier.upsert`, `sale.complete`, `sale.void`, `payment.record`,
`payment.void`, `expense.record`, `expense.void`, `purchase.receive`, `purchase.void`,
`inventory.adjust`, `inventory.count`, `cash.open`, `cash.close`, `dashboard.save`,
`invoice.request`.

## 6. Facturación (J)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/invoices` | `{sale_id, doc_type: "03"\|"01", customer: {doc_type, doc_number, name, address?}}` + `Idempotency-Key` → `202 {invoice_id, series, number, status: "queued"}` |
| GET | `/invoices/{id}` | Estado, motivo de rechazo en lenguaje simple, `pdf_url` firmada (válida 15 min) |
| POST | `/invoices/{id}/credit-notes` | `{reason_code, reason_text, items?}` → nota de crédito (`07`) |
| POST | `/invoices/{id}/retry` | Reintento manual (solo `failed_retryable`; consulta el estado antes de reenviar) |
| POST | `/invoices/{id}/deliveries` | `{channel: "email", to}` → envío; WhatsApp se hace con el *share intent* del dispositivo |
| GET | `/invoices?status=&from=&to=` | Listado para el contador |

**Estados expuestos**: `queued` (en cola), `submitting` (enviando), `accepted` (aceptado),
`observed` (aceptado con observaciones), `rejected` (rechazado), `failed_retryable` (error temporal,
se reintenta), `unknown` (no sabemos si llegó; se consulta antes de reenviar), `voided` (anulado
mediante el procedimiento correspondiente).

La app muestra "Aceptado por SUNAT" **solo** con `accepted` u `observed`, y el servidor solo los
produce con evidencia guardada.

## 7. Asistente IA (P, Fase 6)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/assistant/extractions` | `{kind: "product_photo"\|"purchase_receipt"\|"voice_sale", media_key}` → `202 {extraction_id}` |
| GET | `/assistant/extractions/{id}` | `{status, proposal: {...}, confidence, warnings}`: **propuesta**, nunca un registro |
| POST | `/assistant/extractions/{id}/confirm` | El usuario confirma o edita → se convierte en la operación normal (`purchase.receive`, …) |
| POST | `/assistant/questions` | `{question}` → respuesta basada en consultas de solo lectura sobre los datos del negocio, con las cifras citadas |

## 8. Errores (catálogo inicial)

```json
{
  "type": "https://docs.minegocio.example/errors/sale.totals_mismatch",
  "title": "Los totales de la venta no cuadran",
  "status": 422,
  "code": "sale.totals_mismatch",
  "detail": "La suma de líneas (10.00) no coincide con el total (20.00).",
  "user_message": "Hubo un problema al calcular el total. Vuelve a abrir la venta.",
  "request_id": "req_01936b…"
}
```

| `code` | HTTP | Mensaje para el usuario |
|---|---|---|
| `auth.otp_invalid` | 400 | "El código no es correcto. Revisa el mensaje e inténtalo de nuevo." |
| `auth.otp_rate_limited` | 429 | "Pediste muchos códigos. Espera unos minutos." |
| `authz.forbidden` | 403 | "Tu usuario no tiene permiso para esto. Pídeselo al dueño." |
| `validation.invalid` | 422 | Mensaje por campo |
| `sale.totals_mismatch` | 422 | Ver ejemplo |
| `sale.already_voided` | 200 (idempotente) | — |
| `billing.credit_note_required` | 422 | "Esta venta ya tiene boleta. Para anularla emite una nota de crédito." |
| `billing.customer_doc_required` | 422 | "Para factura necesitas el RUC del cliente." |
| `billing.not_configured` | 422 | "Aún no configuraste tus comprobantes electrónicos." |
| `billing.provider_unavailable` | 503 | "El servicio de comprobantes no responde. Lo intentaremos automáticamente." |
| `plan.limit_reached` | 402 | "Llegaste al límite de tu plan. Tu venta se guardó; mejora tu plan para seguir emitiendo." |
| `sync.device_revoked` | 403 | "Este celular fue desconectado del negocio." |
| `sync.op_conflict` | 409 | (interno) |
| `sync.resync_required` | 410 | (automático) |
| `sync.upgrade_required` | 426 | "Actualiza la app para seguir sincronizando. Tus ventas están guardadas." |
