# Backlog priorizado — MiNegocio AI

Versión 0.1 · Fase 0. Prioridad **MoSCoW** (M = Must, S = Should, C = Could, W = Won't now).
Tamaño: S (≤ 2 días), M (3–5 días), L (1–2 semanas), XL (dividir antes de iniciar).
Criterio de orden: **riesgo primero** (integridad de datos, sincronización y facturación antes que
lo cosmético) y **valor para la primera venta**.

## Definición de "Hecho" (aplica a todo ítem)

1. Código con revisión, *lint* y tipos sin errores (mypy estricto, `dart analyze`).
2. Pruebas automatizadas de los criterios de aceptación, en verde en CI.
3. Reglas de dinero y sincronización con pruebas de propiedades cuando aplique.
4. Documentación actualizada (módulo, API, ADR si hubo una decisión) y entrada en [PROGRESS.md](../PROGRESS.md).
5. Sin secretos en el código; permisos declarados por endpoint.
6. Evidencia adjunta (salida de pruebas, capturas o medición), **no** declaraciones.

---

## Fase 0 — Planificación (en curso)

| ID | Ítem | Prior. | Estado |
|---|---|---|---|
| P0-01 | Estructura documental y PRD | M | ✔ Hecho |
| P0-02 | Arquitectura del sistema y C4 | M | ✔ Hecho |
| P0-03 | Modelo de datos + esquema borrador ejecutable con pruebas | M | ✔ Hecho (41/41 aserciones) |
| P0-04 | Estrategia de sincronización | M | ✔ Hecho |
| P0-05 | Plan SUNAT con estado de verificación de cada regla | M | ✔ Borrador; validaciones pendientes (ver plan) |
| P0-06 | Modelo de amenazas | M | ✔ Hecho |
| P0-07 | Flujo de primera venta (UX) | M | ✔ Hecho |
| P0-08 | Backlog, plan de pruebas y roadmap | M | ✔ Hecho |
| P0-09 | **Revisión de entregables con el responsable del producto** | M | ⏳ Pendiente (bloquea Fase 1) |
| P0-10 | Respuesta a las preguntas bloqueantes ([PHASE0_REPORT](../PHASE0_REPORT.md) §5) | M | ⏳ Pendiente |
| P0-11 | Validación tributaria con contador o asesor (lista en el plan SUNAT §9) | M | ⏳ Pendiente (bloquea Fase 4, no Fase 1) |
| P0-12 | Entrevistas de descubrimiento con 8–10 comerciantes (validar supuestos S1–S4) | S | ⏳ Pendiente |

## Fase 1 — Fundamentos

| ID | Ítem | Prior. | Tam. | Depende de | Historias |
|---|---|---|---|---|---|
| F1-01 | Monorepositorio (`apps/mobile`, `services/api`, `infra`, `docs`), convenciones, `CODEOWNERS`, plantilla de PR | M | S | P0-09 | — |
| F1-02 | Docker Compose: api, worker, postgres, minio, mailpit; `make dev`/`make test` | M | S | F1-01 | — |
| F1-03 | CI: lint, tipos, pruebas, `check_schema.sh`, escaneo de secretos y dependencias | M | M | F1-01 | — |
| F1-04 | Núcleo del backend: config por entorno, errores RFC 9457, logging estructurado, `Money`/`Quantity`, uuid7, `import-linter` | M | M | F1-01 | — |
| F1-05 | Migraciones Alembic desde el esquema borrador (tablas A, B y de soporte) + portar aserciones a pytest | M | M | F1-04 | — |
| F1-06 | Sesión de BD con `SET LOCAL app.business_id` y pruebas de RLS por endpoint | M | M | F1-05 | RNF-09 |
| F1-07 | Autenticación OTP (proveedor *fake* en dev), JWT, refresh rotativo, dispositivos | M | L | F1-05 | US-A-01, A-02 |
| F1-08 | Autorización: permisos por endpoint + recurso; prueba que recorre el router | M | M | F1-07 | US-A-03 |
| F1-09 | Negocios, locales, membresías, invitaciones, revocación de dispositivos | M | M | F1-08 | US-B-01, A-03, A-05 |
| F1-10 | App Flutter: esqueleto feature-first, tema accesible, Riverpod, router, i18n es-PE | M | M | F1-01 | — |
| F1-11 | App: Drift + SQLCipher + migraciones locales + tabla `outbox` | M | M | F1-10 | — |
| F1-12 | App: login OTP, registro de dispositivo, PIN local | M | M | F1-07, F1-11 | US-A-01, A-04 |
| F1-13 | Auditoría transversal (`audit_logs`) con helper de servicio | M | S | F1-05 | — |
| F1-14 | Medición de rendimiento en dispositivo de referencia (arranque, tamaño de APK) en CI | S | M | F1-10 | RNF-02, RNF-04 |
| F1-15 | Panel de observabilidad mínimo (errores, latencia API) | S | S | F1-04 | RNF-13 |

**Criterio de salida de Fase 1**: un usuario se registra con OTP *fake*, crea un negocio sin
conexión, este se sincroniza y otro negocio no puede verlo (prueba automática), con CI en verde.

## Fase 2 — MVP comercial

| ID | Ítem | Prior. | Tam. | Historias |
|---|---|---|---|---|
| F2-01 | Vectores de dinero compartidos Dart/Python (`money_vectors.json`) + implementación en ambos | M | M | ADR-003 |
| F2-02 | **SyncEngine**: outbox, push por lotes, backoff, recuperación de `sending`, pull por cursor, `pending_conflicts` | M | XL→dividir | US-M-01, M-02, M-04 |
| F2-03 | Servidor de sincronización: `sync_events` idempotente, despacho, `sync_changes`, snapshot | M | L | US-M-03 |
| F2-04 | Catálogo: productos, variantes, favoritos, código de barras (escáner ML Kit) | M | L | US-D-01…05 |
| F2-05 | Venta rápida + cobro (efectivo con vuelto, Yape, Plin, tarjeta, mixto) | M | L | US-G-01, H-01…03 |
| F2-06 | Inventario: kardex, proyección, ajustes, conteo, alertas | M | L | US-F-01…05 |
| F2-07 | Compras y proveedores con costo promedio | M | M | US-E-01…04 |
| F2-08 | Clientes y fiado (saldo, abonos, estado de cuenta) | M | M | US-I-01…03 |
| F2-09 | Anulaciones con motivo, PIN y compensación | M | M | US-G-04, H-05 |
| F2-10 | Caja (apertura, cierre, arqueo) y gastos | M | M | US-K-01…03 |
| F2-11 | Venta guiada | S | M | US-G-02 |
| F2-12 | Producto libre, descuentos, nota de venta por WhatsApp | S | M | US-G-03, G-05, G-06 |
| F2-13 | **Batería de caos de sincronización** (N dispositivos, duplicados, reordenamiento, cortes, relojes) | M | L | RF-11 |
| F2-14 | Conciliación de Yape/Plin manual | C | S | US-H-04 |

**Criterio de salida**: piloto interno con 2 dispositivos durante 5 días de uso real o simulado; 0
duplicados y 0 pérdidas en la batería de caos; invariantes de stock y saldo verificados.

## Fase 3 — Experiencia

| ID | Ítem | Prior. | Tam. | Historias |
|---|---|---|---|---|
| F3-01 | Onboarding de 5 preguntas + plantillas por rubro + venta de práctica | M | L | US-C-01…03 |
| F3-02 | Dashboard con 10 widgets, personalización y sincronización | M | L | US-L-01…03 |
| F3-03 | Reportes (día, periodo, margen, flujo, por cobrar) con trazabilidad | M | L | US-K-04, K-05 |
| F3-04 | Exportación para contador | S | M | US-K-06 |
| F3-05 | Pruebas de usabilidad (2 rondas × 8 comerciantes) y correcciones | M | L | O1, O2 |
| F3-06 | Importación desde Excel/CSV | S | M | US-D-06 |
| F3-07 | Recordatorios de fiado | C | S | US-I-04 |
| F3-08 | Auditoría de accesibilidad (TalkBack, fuente al 200 %, contraste) | M | M | RNF-11 |

## Fase 4 — Facturación

Precondición: P0-11 (validación tributaria) y elección del proveedor (pregunta bloqueante Q3).

| ID | Ítem | Prior. | Tam. | Historias |
|---|---|---|---|---|
| F4-01 | Interfaz `BillingProvider` + `FakeBillingProvider` + pruebas de contrato | M | M | ADR-004 |
| F4-02 | Adaptador del proveedor elegido (solo ambiente de pruebas) | M | L | — |
| F4-03 | Configuración tributaria y asistente de alta | M | L | US-J-01 |
| F4-04 | Series, correlativos y emisión de boleta y factura | M | L | US-J-02, J-03 |
| F4-05 | Máquina de estados, worker, reintentos seguros y consulta previa a reenviar | M | L | US-J-04 |
| F4-06 | Notas de crédito y débito | M | M | US-J-05 |
| F4-07 | PDF y entrega por WhatsApp o correo | M | M | US-J-06 |
| F4-08 | Descarga para contador | S | S | US-J-07 |
| F4-09 | Pruebas de extremo a extremo en el ambiente de pruebas del proveedor | M | M | — |
| F4-10 | Activación en producción **con aprobación explícita** y piloto con 3–5 negocios | M | M | O6 |

## Fase 5 — SaaS

| ID | Ítem | Prior. | Tam. |
|---|---|---|---|
| F5-01 | Planes, límites y uso; nunca bloquear ventas | M | L |
| F5-02 | Pasarela de suscripción y *webhooks* idempotentes | M | L |
| F5-03 | Panel administrativo con acceso de soporte por *grant* | M | L |
| F5-04 | Despliegue de producción: HTTPS, copias verificadas, PITR, alertas | M | L |
| F5-05 | Multi-local (B-03) | S | L |
| F5-06 | Pruebas de carga (1 000 negocios × 200 ventas/día simuladas) | S | M |

## Fase 6 — IA

| ID | Ítem | Prior. | Tam. |
|---|---|---|---|
| F6-01 | Evaluación de proveedores (costo por operación, latencia, privacidad, opción local) con conjunto de evaluación | M | M |
| F6-02 | Compra por foto del comprobante del proveedor (propuesta + confirmación) | M | L |
| F6-03 | Producto por foto | S | M |
| F6-04 | Venta por voz (reconocimiento en el dispositivo primero) | S | L |
| F6-05 | Preguntas sobre los datos con respuestas citadas | S | L |
| F6-06 | Recomendaciones de reposición e inconsistencias | C | M |

## Won't (por ahora)

iOS · tienda en línea · pasarela de cobro integrada · SIRE · guías de remisión · planillas ·
rubros regulados sin validar (farmacias) · órdenes de compra · producción y recetas (panaderías y
restaurantes; se evaluará después del piloto).
