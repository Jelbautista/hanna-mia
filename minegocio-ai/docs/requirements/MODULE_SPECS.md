# Especificación de módulos — MiNegocio AI

Versión 0.1 · Fase 0. Las historias (`US-x-nn`) están en [USER_STORIES.md](USER_STORIES.md). Las
tablas, en [DATABASE_DESIGN.md](../architecture/DATABASE_DESIGN.md). Los endpoints, en
[API_CONTRACTS.md](../architecture/API_CONTRACTS.md).

## 0. Matriz de permisos

Roles del sistema: **Dueño** (`owner`), **Administrador** (`admin`), **Vendedor** (`cashier`) y
**Contador** (`accountant`, solo lectura). Los roles de plataforma (`support`, `platform_admin`) son
independientes y nunca dan acceso implícito a datos de un negocio (ver módulo O).

| Permiso | Dueño | Admin | Vendedor | Contador |
|---|:-:|:-:|:-:|:-:|
| Vender, cobrar, registrar cliente | ✔ | ✔ | ✔ | — |
| Ver costos y márgenes | ✔ | ✔ | — (configurable) | ✔ |
| Anular venta o cobro | ✔ | ✔ | Con PIN de dueño/admin | — |
| Crear y editar productos y precios | ✔ | ✔ | Solo si se habilita | — |
| Registrar compras y ajustes de inventario | ✔ | ✔ | Configurable | — |
| Abrir y cerrar caja | ✔ | ✔ | ✔ (su dispositivo) | — |
| Registrar gastos | ✔ | ✔ | Configurable | — |
| Emitir comprobantes | ✔ | ✔ | ✔ | — |
| Notas de crédito | ✔ | ✔ | — | — |
| Reportes completos y exportación | ✔ | ✔ | Solo "mis ventas de hoy" | ✔ |
| Miembros, dispositivos, datos tributarios | ✔ | Miembros y dispositivos | — | — |
| Suscripción y pagos del plan | ✔ | — | — | — |
| Eliminar negocio / transferir propiedad | ✔ | — | — | — |

Regla transversal: la autorización se evalúa en el servidor por **acción + recurso + negocio**, y
también en la app para la UX (ocultar lo no permitido). La app nunca es la única barrera.

---

## A. Identidad, usuarios y roles

- **Objetivo**: acceso simple y seguro con el número de celular; un usuario puede pertenecer a varios negocios.
- **Usuarios y permisos**: cualquier persona (registro); dueño y admin gestionan miembros.
- **Historias**: US-A-01 a US-A-05.
- **Casos de uso**: solicitar código; verificar y registrar dispositivo; refrescar sesión; crear o
  cambiar PIN local; invitar miembro (enlace o código por WhatsApp); aceptar invitación; revocar
  dispositivo o miembro; cambiar de negocio activo.
- **Entidades**: `users`, `roles`, `memberships`, `devices`; en servidor también `otp_challenges`
  (hash del código, intentos, vencimiento) y `refresh_tokens` (familia, hash, dispositivo, revocado).
- **Reglas de negocio**:
  1. Código de 6 dígitos, válido 5 min, máximo 5 intentos; máximo 3 códigos por número cada 15 min
     y límites por IP y por prefijo (contra *SMS pumping*).
  2. *Refresh token* rotativo: reutilizar uno ya usado revoca toda la familia.
  3. Un negocio tiene al menos un dueño activo; el último dueño no puede salir sin transferir.
  4. El PIN (4–6 dígitos) se guarda con hash y sal en el servidor y en el dispositivo; 5 fallos →
     espera creciente.
  5. Revocar un dispositivo invalida sus tokens y detiene su sincronización (E9 en
     [SYNC_STRATEGY](../architecture/SYNC_STRATEGY.md)).
- **API y eventos**: `/auth/*`, `/me`, `/members`, `/devices`. Eventos: `UserRegistered`,
  `DeviceRegistered`, `DeviceRevoked`, `MembershipChanged`.
- **Validaciones**: celular E.164 (Perú `+51 9XXXXXXXX` por defecto); nombre de 1 a 120 caracteres.
- **Errores**: `auth.otp_invalid`, `auth.otp_expired`, `auth.otp_rate_limited`,
  `auth.refresh_reused`, `members.last_owner`.
- **Dependencias**: proveedor de SMS/WhatsApp (por decidir), B.
- **Pruebas**: límites de intentos; rotación y reutilización de *refresh*; matriz de permisos
  generada por endpoint; revocación con sincronización en curso.
- **Criterios de aceptación**: alta en ≤ 60 s; ningún endpoint sin declaración de permiso (prueba de
  CI que recorre el router); 0 accesos con token revocado.

## B. Negocios, establecimientos y configuración

- **Objetivo**: representar el negocio (tenant), sus locales y su configuración tributaria y operativa.
- **Usuarios y permisos**: dueño (todo); admin (locales y preferencias).
- **Historias**: US-B-01 a US-B-04.
- **Casos de uso**: crear negocio (con local principal y membresía de dueño); editar datos; registrar
  RUC y régimen; crear local; configurar preferencias (stock negativo, roles que ven costos, modo de
  venta por defecto, redondeo de efectivo).
- **Entidades**: `businesses`, `establishments`, `memberships`; `business_settings` (jsonb validado
  por esquema, versionado).
- **Reglas de negocio**:
  1. RUC de 11 dígitos con prefijo válido y dígito verificador (algoritmo módulo 11). La consulta del
     estado del RUC depende de una fuente oficial o un proveedor (pendiente).
  2. El régimen determina las opciones que se ofrecen en J (por ejemplo, Nuevo RUS: sin factura;
     ver [INTEGRATION_PLAN](../sunat/INTEGRATION_PLAN.md) §2), **nunca** el cálculo de ventas
     pasadas.
  3. Un negocio cerrado conserva sus datos durante el plazo de retención y queda en solo lectura.
- **API y eventos**: `/businesses`, `/business`, `/establishments`, `/business/tax-profile`. Eventos:
  `BusinessCreated`, `TaxProfileChanged`, `EstablishmentCreated`.
- **Validaciones**: nombre obligatorio; ubigeo de 6 dígitos; zona horaria `America/Lima` por defecto.
- **Errores**: `business.ruc_invalid`, `business.ruc_in_use`, `business.closed`.
- **Dependencias**: A; N (límite de locales).
- **Pruebas**: algoritmo de RUC con vectores; aislamiento (T01, T02, T36–T40); cierre de negocio.
- **Criterios de aceptación**: crear un negocio funciona sin conexión (se sincroniza después);
  cambiar el régimen no modifica ventas registradas.

## C. Onboarding conversacional y guiado

- **Objetivo**: llegar a la primera venta en ≤ 5 min configurando el sistema a partir del rubro.
- **Usuarios y permisos**: dueño en el primer uso; cualquier miembro puede ver la guía.
- **Historias**: US-C-01 a US-C-03.
- **Casos de uso**: flujo de 5 preguntas ([FIRST_SALE_FLOW](../ux/FIRST_SALE_FLOW.md)); aplicar
  plantilla de rubro; venta de práctica; retomar el onboarding pendiente.
- **Entidades**: `business_templates` (servidor, versionadas: productos sugeridos, widgets, ajustes) y
  `onboarding_state` (local + sincronizado en `business_settings`).
- **Reglas**: todo paso es omitible; aplicar una plantilla es idempotente (no duplica productos si se
  repite); la venta de práctica nunca se sincroniza.
- **API y eventos**: `GET /templates?business_type=` (también embebidas en la app para uso sin
  conexión). Evento: `OnboardingCompleted{steps_skipped}`.
- **Validaciones**: precios sugeridos vacíos (el comerciante los define; no se inventan precios).
- **Errores**: ninguno bloqueante; las fallas de plantilla degradan a "Escribirlos yo".
- **Dependencias**: B, D, L.
- **Pruebas**: widget tests del flujo; prueba de usabilidad (Fase 3); idempotencia de la plantilla.
- **Criterios de aceptación**: mediana ≤ 5 min hasta la primera venta en la prueba de usabilidad;
  ≥ 7 de 8 participantes sin ayuda.

## D. Productos, categorías, variantes y códigos de barras

- **Objetivo**: catálogo fácil de crear y rápido de buscar.
- **Usuarios y permisos**: dueño y admin; vendedor si se habilita.
- **Historias**: US-D-01 a US-D-06.
- **Casos de uso**: alta manual (nombre + precio); alta por escaneo; variantes (talla, sabor,
  medida); marcar favoritos y ordenar la grilla; cambiar precio; archivar; importar desde plantilla
  o CSV (Fase 3).
- **Entidades**: `categories`, `products`, `product_variants`.
- **Reglas**:
  1. Todo producto tiene al menos una variante; la variante por defecto es invisible para quien no
     usa variantes.
  2. Código de barras único por negocio entre productos activos (T00: puede repetirse entre negocios).
  3. El precio incluye impuestos; el cambio de precio no afecta ventas registradas.
  4. La unidad y la afectación al IGV se toman de catálogos SUNAT versionados (pendiente de
     validación); por defecto, `NIU` (unidad) y gravado.
  5. Archivar oculta el producto de la venta pero conserva su historial.
- **API y eventos**: `/products`, `/categories`, `/products/by-barcode/{code}`; operaciones
  `product.upsert`/`product.archive`. Eventos: `ProductCreated`, `PriceChanged{old,new,by}`.
- **Validaciones**: nombre de 1 a 160 caracteres; precio ≥ 0 con hasta 4 decimales; código de
  barras de 4 a 64 caracteres alfanuméricos (EAN-13 con verificación de dígito cuando aplica).
- **Errores**: `catalog.barcode_in_use`, `catalog.name_required`, `catalog.price_invalid`.
- **Dependencias**: B; N (límite de productos).
- **Pruebas**: búsqueda en 5 000 productos ≤ 150 ms p95 (dispositivo); conflictos de edición (§5.4
  de sincronización); unicidad del código de barras.
- **Criterios de aceptación**: alta manual ≤ 20 s; escaneo → producto encontrado ≤ 1 s.

## E. Proveedores, compras y recepción de mercadería

- **Objetivo**: registrar lo que entra al negocio para tener stock y costos correctos.
- **Usuarios y permisos**: dueño y admin; vendedor configurable.
- **Historias**: US-E-01 a US-E-04.
- **Casos de uso**: registrar compra recibida (proveedor opcional, ítems, costo por unidad o total de
  línea, comprobante del proveedor opcional y foto); compra pagada o pendiente; pagar compra
  pendiente; anular compra con motivo.
- **Entidades**: `suppliers`, `purchases`, `purchase_items`; movimientos `purchase_receipt` en F;
  egreso en K si se paga.
- **Reglas**:
  1. Recibir actualiza el kardex y el **costo promedio ponderado**:
     `nuevo_costo = (stock_previo⁺ × costo_previo + cant × costo_unit) / (stock_previo⁺ + cant)`,
     donde `stock_previo⁺ = max(stock_previo, 0)` para que el stock negativo no distorsione el costo.
  2. Si el usuario ingresa el total de la línea, `unit_cost = total / cantidad` con 4 decimales.
  3. Anular genera movimientos `purchase_void` inversos; si el stock resultante es negativo, se
     permite y se alerta.
  4. MVP: compras ya recibidas (no hay órdenes de compra).
- **API y eventos**: `/purchases`, `/suppliers`; `purchase.receive`/`purchase.void`. Evento:
  `PurchaseReceived` → F (kardex) y K (egreso si está pagada).
- **Validaciones**: cantidad > 0; costo ≥ 0; RUC del proveedor con formato si se ingresa.
- **Errores**: `purchase.empty`, `purchase.already_voided`.
- **Dependencias**: D, F, K.
- **Pruebas**: propiedad: el costo promedio está entre el mínimo y el máximo de los costos de
  entrada; anulación que restaura el stock; costo con stock previo negativo.
- **Criterios de aceptación**: tras recibir, el stock y el costo se reflejan al instante sin conexión
  y quedan consolidados tras sincronizar.

## F. Inventario, movimientos, ajustes y alertas

- **Objetivo**: saber cuánto hay de cada producto y por qué cambió.
- **Usuarios y permisos**: ver stock (todos los operativos); ajustar (dueño y admin; vendedor
  configurable).
- **Historias**: US-F-01 a US-F-05.
- **Casos de uso**: consultar stock; ver historial del producto; corregir cantidad con motivo;
  conteo físico (uno o varios productos); configurar mínimo; recibir alertas de stock bajo o negativo.
- **Entidades**: `inventory_movements` (kardex), `stock_levels` (proyección).
- **Reglas**: ver [DATABASE_DESIGN](../architecture/DATABASE_DESIGN.md) §5 y
  [SYNC_STRATEGY](../architecture/SYNC_STRATEGY.md) §5.3. Invariante: `stock_levels.quantity = Σ
  movimientos` por local y variante. Productos con `tracks_stock = false` (platos, servicios) no
  generan movimientos.
- **API y eventos**: `/stock`, `/inventory/movements`, `/inventory/adjustments`, `/inventory/counts`.
  Eventos: `StockLow{variant, qty, min}`, `StockNegative`, `CountNeedsReview`.
- **Validaciones**: delta ≠ 0; motivo obligatorio (T10); cantidad con hasta 3 decimales.
- **Errores**: `inventory.reason_required`, `inventory.product_not_tracked`.
- **Dependencias**: D, E, G.
- **Pruebas**: invariante del kardex en pruebas de propiedades y de caos; idempotencia (T08);
  inmutabilidad (T09); conteo concurrente (secuencia §4).
- **Criterios de aceptación**: el 100 % de los cambios de stock tiene movimiento con autor,
  dispositivo, hora y motivo; la alerta de stock bajo aparece en ≤ 1 s localmente.

## G. Ventas rápidas y ventas guiadas

- **Objetivo**: registrar ventas con el mínimo esfuerzo y sin errores de cálculo.
- **Usuarios y permisos**: todos los roles operativos; anular según la matriz.
- **Historias**: US-G-01 a US-G-06.
- **Casos de uso**: venta rápida; venta guiada; producto libre por monto; descuento por línea;
  asociar cliente; venta al fiado (con I); anular; compartir nota de venta; pedir comprobante (J).
- **Entidades**: `sales`, `sale_items`; borradores solo locales (`sale_drafts`).
- **Reglas**:
  1. Cálculo de líneas e impuestos según [ADR-003](../decisions/ADR-003.md), con los mismos vectores
     de prueba en Dart y Python.
  2. Numeración local `D{device_code:03}-{seq:06}` sin huecos por dispositivo. **No** es un
     correlativo tributario.
  3. Venta completada inmutable; anular exige motivo y, si anula un vendedor, autorización con PIN
     (T11–T14, T20). Venta con comprobante aceptado → nota de crédito (J).
  4. "Deshacer" durante 5 s anula sin pedir PIN, con motivo automático `undo` y auditoría.
  5. Nunca se rechaza una venta por stock (E1).
  6. Producto libre: variante técnica "Producto libre" por negocio, con descripción editable y
     afectación por defecto del negocio.
- **API y eventos**: `sale.complete`, `sale.void`; `/sales`. Eventos: `SaleCompleted` → F, H, L;
  `SaleVoided` → F, H, J.
- **Validaciones**: ≥ 1 línea; cantidad > 0; descuento ≤ importe de la línea; totales que cuadran (T05–T07).
- **Errores**: `sale.empty`, `sale.totals_mismatch`, `sale.already_voided` (idempotente),
  `billing.credit_note_required`.
- **Dependencias**: D, F, H, I, J, K.
- **Pruebas**: propiedades de dinero (Hypothesis / `glados` en Dart); conteo de toques en pruebas de
  integración; p95 ≤ 300 ms en dispositivo.
- **Criterios de aceptación**: ≤ 3 toques (favorito + efectivo exacto); 0 diferencias entre Dart y
  Python en los vectores de dinero.

## H. Cobros, métodos de pago y conciliación

- **Objetivo**: saber cómo y cuánto pagaron, y cuadrar Yape/Plin con lo registrado.
- **Usuarios y permisos**: registrar (operativos); anular y conciliar (dueño y admin).
- **Historias**: US-H-01 a US-H-05.
- **Casos de uso**: cobro en efectivo con vuelto; Yape, Plin, tarjeta o transferencia con número de
  operación; pago mixto; abono a fiado; devolución; conciliación manual ("marcar como verificado en
  mi app de Yape").
- **Entidades**: `payments` (`kind` = `payment` | `refund`).
- **Reglas**:
  1. Importe > 0; `tendered ≥ amount` en efectivo; vuelto = `tendered − amount`, que no se guarda
     como cobro.
  2. Σ cobros de una venta ≤ total; la diferencia es saldo de fiado (requiere cliente).
  3. Inmutable salvo `status → voided` y la conciliación (T16).
  4. Integraciones automáticas de conciliación: **fuera del MVP**, pendiente de investigar si existe
     una API oficial para comercios.
- **API y eventos**: `payment.record`, `payment.void`; `/payments/{id}/reconcile`. Eventos:
  `PaymentRecorded` → I, K, L.
- **Validaciones**: método del catálogo; referencia ≤ 64 caracteres.
- **Errores**: `payment.exceeds_balance`, `payment.customer_required`, `payment.already_voided`.
- **Dependencias**: G, I, K.
- **Pruebas**: propiedad del saldo (Σ ventas − Σ abonos ≥ 0 salvo saldo a favor explícito); pago mixto.
- **Criterios de aceptación**: el vuelto es exacto al céntimo; el reporte "Te pagaron por método"
  cuadra con la suma de cobros.

## I. Clientes y cuentas por cobrar

- **Objetivo**: controlar el fiado y tener los datos para la factura.
- **Usuarios y permisos**: crear y ver (operativos); límite de crédito (dueño y admin).
- **Historias**: US-I-01 a US-I-04.
- **Casos de uso**: alta rápida (nombre + celular); con documento (DNI/RUC) para comprobantes; venta
  al fiado; abono; estado de cuenta compartible por WhatsApp; recordatorio de pago (mensaje
  prellenado, nunca envío automático en MVP).
- **Entidades**: `customers`; saldo derivado de `sales` y `payments`.
- **Reglas**: el saldo se calcula, no se guarda como valor editable; aviso (no bloqueo) al superar el
  límite de crédito; fusión de duplicados por documento ([SYNC_STRATEGY](../architecture/SYNC_STRATEGY.md) §5.4).
- **Datos personales**: minimización (solo nombre y celular por defecto); el comerciante es
  responsable del tratamiento de sus clientes y MiNegocio actúa como encargado (a validar
  legalmente, [THREAT_MODEL](../security/THREAT_MODEL.md) §7).
- **API y eventos**: `customer.upsert`, `/customers/{id}/statement`. Eventos: `CreditLimitExceeded`.
- **Validaciones**: DNI de 8 dígitos y RUC de 11 con verificación; celular E.164.
- **Errores**: `customer.doc_invalid`, `customer.duplicate` (sugerencia de fusión).
- **Dependencias**: G, H.
- **Pruebas**: saldo en secuencias aleatorias de ventas, abonos y anulaciones; fusión.
- **Criterios de aceptación**: "Te deben" = Σ saldos de clientes; el estado de cuenta muestra cada
  movimiento con fecha.

## J. Facturación electrónica SUNAT

- **Objetivo**: emitir comprobantes válidos desde la venta, sin confundir venta con comprobante.
- **Usuarios y permisos**: emitir (operativos); notas de crédito y configuración (dueño y admin);
  contador (lectura y descarga).
- **Historias**: US-J-01 a US-J-07.
- **Casos de uso**: configurar facturación (validación del RUC, régimen, series, alta en el
  proveedor); emitir boleta o factura; consultar estado; reintentar; nota de crédito o débito;
  generar PDF; entregar por WhatsApp o correo; descargar para el contador.
- **Entidades**: `invoice_series`, `invoices`, `invoice_events`; evidencia en almacenamiento de objetos.
- **Reglas**: ver [INTEGRATION_PLAN](../sunat/INTEGRATION_PLAN.md). Clave: estado `accepted` u
  `observed` solo con evidencia (T26); producción bloqueada fuera de producción (T27); correlativo
  asignado en el servidor con bloqueo de fila; un comprobante vigente por venta (T30); inmutable
  (T31, T32, T34); nunca reenviar a ciegas un estado `unknown`.
- **API y eventos**: `/invoices`, `invoice.request`. Eventos: `InvoiceRequested`, `InvoiceAccepted`,
  `InvoiceRejected`, `InvoiceNeedsAttention`.
- **Validaciones**: según el tipo de comprobante (factura: RUC del adquirente, T28; boleta: umbral
  de identificación del adquirente **pendiente de validación**); fechas de emisión dentro de los
  plazos permitidos (pendiente).
- **Errores**: `billing.not_configured`, `billing.customer_doc_required`,
  `billing.provider_unavailable`, `billing.rejected{sunat_code}`, `billing.credit_note_required`.
- **Dependencias**: B, G, I, N (cupo de comprobantes), proveedor externo.
- **Pruebas**: contrato del `BillingProvider` contra `FakeBillingProvider` y el ambiente de pruebas
  del proveedor; caos (timeouts, respuestas duplicadas); transiciones de estado.
- **Criterios de aceptación**: 0 comprobantes "aceptados" sin evidencia; 0 envíos a producción desde
  entornos no productivos; ≥ 98 % aceptados sin intervención en el piloto.

## K. Gastos, caja y reportes financieros

- **Objetivo**: saber cuánta plata hay, en qué se gastó y cuánto se gana.
- **Usuarios y permisos**: caja (operativos en su dispositivo); gastos y reportes (según la matriz).
- **Historias**: US-K-01 a US-K-06.
- **Casos de uso**: abrir caja con fondo; registrar gasto (categoría simple, foto opcional); retiro o
  ingreso de efectivo; cerrar caja con conteo (calculadora de billetes y monedas); reportes del día,
  de la semana y del mes; exportación para el contador (CSV/Excel).
- **Entidades**: `cash_sessions`, `expenses`; reportes derivados (vistas o tablas agregadas).
- **Reglas**:
  1. Efectivo esperado = fondo + cobros en efectivo − devoluciones en efectivo − gastos en efectivo
     ± retiros e ingresos.
  2. Diferencia = contado − esperado; se registra, no se "corrige".
  3. Definiciones financieras del [PRD](PRD.md) §8 (ventas ≠ ingresos ≠ utilidad ≠ flujo).
  4. Toda cifra de reporte es reproducible desde las operaciones (prueba de conciliación).
- **API y eventos**: `cash.open`/`cash.close`, `expense.record`, `/reports/*`. Eventos:
  `CashSessionClosed{difference}`.
- **Validaciones**: importe > 0; categoría del catálogo; conteo ≥ 0.
- **Errores**: `cash.already_open`, `cash.not_open` (aviso: se permite vender sin caja si el negocio
  no la usa).
- **Dependencias**: G, H, E.
- **Pruebas**: conciliación de reportes con datos sintéticos de 90 días; zona horaria (cortes de
  día en `America/Lima`).
- **Criterios de aceptación**: los reportes coinciden al céntimo con la suma de operaciones.

## L. Dashboard personalizable

- **Objetivo**: ver de un vistazo lo que importa a cada negocio.
- **Usuarios y permisos**: cada miembro ve los widgets que su rol permite (un vendedor no ve el
  margen si no tiene permiso).
- **Historias**: US-L-01 a US-L-03.
- **Casos de uso**: ver dashboard; mostrar, ocultar y ordenar widgets; restablecer la plantilla del
  rubro; tocar un número para ver el detalle.
- **Entidades**: `dashboard_preferences` (layout jsonb).
- **Widgets iniciales**: Ventas del día · Número de operaciones · Ingresos cobrados (por método) ·
  Cuentas pendientes (te deben) · Costo de lo vendido · Margen bruto estimado · Stock bajo ·
  Productos más vendidos · Compras recientes · Gastos registrados.
- **Reglas**: cálculo local sobre SQLite (funciona sin conexión) con las definiciones del PRD §8; el
  margen se rotula "estimado" y avisa si hay productos sin costo ("3 productos sin costo: el margen
  puede ser mayor al real"); preferencias con última escritura gana.
- **API y eventos**: `dashboard.save`, `/dashboard/preferences`.
- **Validaciones**: layout que valida contra el esquema de widgets conocido; widgets desconocidos se
  ignoran (compatibilidad entre versiones).
- **Errores**: ninguno bloqueante.
- **Dependencias**: G, H, I, F, E, K.
- **Pruebas**: cada widget contra un conjunto de datos fijo con el resultado esperado; rendimiento
  (≤ 500 ms para calcular el dashboard con 10 000 ventas locales).
- **Criterios de aceptación**: el cambio de layout se refleja en otro celular del mismo miembro tras
  sincronizar.

## M. Sincronización offline-first

Especificación completa en [SYNC_STRATEGY.md](../architecture/SYNC_STRATEGY.md).

- **Objetivo**: trabajar sin conexión sin perder ni duplicar datos.
- **Usuarios y permisos**: transparente; el dueño ve el estado de todos los dispositivos.
- **Historias**: US-M-01 a US-M-04.
- **Entidades**: `sync_events`, `sync_changes`, `devices`; en el dispositivo, `outbox`,
  `sync_state` y `pending_conflicts`.
- **Reglas, API, errores, pruebas y criterios**: ver el documento enlazado (§1 garantías, §5
  conflictos, §6 escenarios E1–E12, §7 monitoreo).

## N. Suscripciones y planes SaaS

- **Objetivo**: monetizar sin poner en riesgo la operación del comerciante.
- **Usuarios y permisos**: dueño.
- **Historias**: US-N-01 a US-N-03.
- **Casos de uso**: ver plan y consumo; prueba gratuita; mejorar o bajar de plan; pago recurrente;
  gestión de mora.
- **Entidades**: `plans`, `subscriptions`; `usage_counters` por periodo (comprobantes, IA,
  dispositivos).
- **Reglas**:
  1. **Nunca se bloquea una venta** ni el acceso a los datos propios por límite o mora. Se limitan
     funciones adicionales (nuevos dispositivos, emisión por encima del cupo, IA).
  2. En mora: periodo de gracia (duración por decidir), luego solo lectura de funciones premium, con
     exportación siempre disponible.
  3. Límites evaluados en el servidor; la app los replica para avisar sin conexión.
- **API y eventos**: `/subscription`, `/plans`, *webhooks* de la pasarela (firmados e idempotentes).
- **Validaciones**: plan activo; cambios con prorrateo (por definir).
- **Errores**: `plan.limit_reached` (402).
- **Dependencias**: pasarela de pago (por decidir); A, B.
- **Pruebas**: *webhooks* duplicados o desordenados; límites sin conexión.
- **Criterios de aceptación**: 0 ventas bloqueadas por motivos de plan en las pruebas.

## O. Panel administrativo y soporte

- **Objetivo**: operar la plataforma y ayudar a los comerciantes sin vulnerar su privacidad.
- **Usuarios y permisos**: `support` y `platform_admin`, con doble factor obligatorio.
- **Historias**: US-O-01 a US-O-03.
- **Casos de uso**: buscar negocio por id o celular del dueño; ver salud de sincronización y
  facturación; **acceso a datos del negocio solo con consentimiento** del dueño, por tiempo limitado
  y auditado; gestionar plantillas de rubro y catálogos tributarios; métricas de plataforma.
- **Entidades**: `support_access_grants` (negocio, agente, alcance, vencimiento, motivo); `audit_logs`
  con `actor_type='support'`.
- **Reglas**: acceso por defecto solo a metadatos técnicos (conteos, errores, estados), sin datos
  comerciales ni personales; cualquier acceso a datos queda registrado y es visible para el dueño
  ("Soporte vio tus ventas el 19/11 a las 15:40").
- **API y eventos**: `/admin/*` (red y autenticación separadas, Fase 5).
- **Validaciones, errores y dependencias**: A, todos los módulos (lectura).
- **Pruebas**: un agente sin *grant* no accede (pruebas de autorización); auditoría de cada acceso.
- **Criterios de aceptación**: el 100 % de los accesos de soporte a datos de negocio tiene *grant*
  vigente y registro.

## P. Asistente de IA (voz, imágenes y análisis comercial)

Decisión base: [ADR-006](../decisions/ADR-006.md).

- **Objetivo**: reducir el trabajo de digitación y explicar los números, siempre bajo control del
  usuario.
- **Usuarios y permisos**: según el plan; el dueño activa o desactiva la IA y el envío de datos a
  proveedores externos.
- **Historias**: US-P-01 a US-P-05.
- **Casos de uso**: producto por foto (nombre y categoría sugeridos; **el precio nunca se inventa**);
  compra por foto del comprobante del proveedor (extracción de ítems, cantidades y costos); venta por
  voz ("dos gaseosas y un pan"); preguntas ("¿cuánto gané esta semana?"); recomendaciones de
  reposición; detección de inconsistencias (precio de venta menor al costo, ventas duplicadas
  probables, stock negativo recurrente).
- **Entidades**: `ai_extractions` (propuesta, confianza, estado
  `proposed`/`confirmed`/`discarded`, costo estimado), `ai_usage`.
- **Reglas**:
  1. Toda salida es una **propuesta**; al confirmarla se convierte en la operación normal
     (`purchase.receive`, `sale.complete`) con autor humano.
  2. La IA no anula, no emite comprobantes, no cambia precios ni ejecuta acciones irreversibles.
  3. Las respuestas de análisis se basan en consultas de solo lectura y citan las cifras de origen.
  4. El texto extraído de imágenes es **dato no confiable** (protección contra instrucciones
     inyectadas en la imagen).
  5. Minimización: no se envían datos personales de clientes al proveedor de IA; las imágenes se
     borran del proveedor según su política, que debe ser compatible con el uso (evaluar).
- **API y eventos**: `/assistant/*` ([API_CONTRACTS](../architecture/API_CONTRACTS.md) §7).
- **Validaciones**: lo extraído pasa por las mismas validaciones que la entrada manual.
- **Errores**: `assistant.disabled`, `assistant.quota_exceeded`, `assistant.low_confidence`.
- **Dependencias**: D, E, G, K; proveedor de IA (por decidir con evaluación de costo, latencia y
  privacidad).
- **Pruebas**: conjunto de evaluación con ≥ 100 comprobantes reales anonimizados (precisión por
  campo); pruebas de inyección; verificación de que ninguna ruta de IA escribe sin confirmación.
- **Criterios de aceptación**: precisión ≥ 90 % por campo en comprobantes impresos legibles (meta a
  validar); 0 escrituras sin confirmación humana.
