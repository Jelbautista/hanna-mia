# Plan de pruebas — MiNegocio AI

Versión 0.1 · Fase 0

## 1. Objetivos

Demostrar con evidencia automatizada que el sistema: registra ventas correctamente, no duplica ni
pierde datos al sincronizar, aísla a los negocios, conserva la trazabilidad del inventario, se
recupera de cortes de conectividad, calcula importes de forma consistente, protege datos y
credenciales, y separa las ventas registradas de los comprobantes tributarios válidos.

**No se inventan resultados**: cada criterio se cierra con la salida de una prueba enlazada en
[PROGRESS.md](PROGRESS.md).

## 2. Pirámide y herramientas

| Nivel | Backend | App | Objetivo |
|---|---|---|---|
| Unitarias de dominio | pytest + **Hypothesis** (propiedades) | `flutter test` + `glados` (propiedades) | Reglas de dinero, stock, estados y permisos |
| Base de datos | `schema_checks.sql` (Fase 0) → pytest + testcontainers PostgreSQL | Pruebas de Drift en memoria con migraciones | Restricciones, RLS, triggers |
| Integración | pytest + httpx `AsyncClient` contra la API real + PostgreSQL efímero | Pruebas de repositorios + `SyncEngine` contra un servidor *fake* | Casos de uso de punta a punta en un módulo |
| Contrato | OpenAPI ⇄ `API_CONTRACTS.md` (schemathesis); `BillingProvider` *fake* ⇄ real | Cliente generado ⇄ OpenAPI | Compatibilidad |
| Caos de sincronización | Simulador de N dispositivos (Python) contra la API real | `integration_test` con red intermitente simulada | G1–G6 de la estrategia de sincronización |
| E2E | — | `integration_test` / Patrol en dispositivo físico de referencia y emulador | Flujos críticos |
| Rendimiento | Locust o k6 (Fase 5) | Medición de arranque, venta y búsqueda en dispositivo de referencia | RNF-01…05 |
| Seguridad | Bandit, Semgrep, pip-audit, gitleaks, pruebas de autorización por endpoint | `dart analyze`, osv-scanner | THREAT_MODEL §6 |
| Accesibilidad | — | Guías de accesibilidad de Flutter, escala de fuente al 200 %, TalkBack manual | RNF-11 |
| Usabilidad | — | Sesiones con comerciantes ([FIRST_SALE_FLOW](ux/FIRST_SALE_FLOW.md) §7) | O1, O2 |

## 3. Matriz de criterios de calidad → pruebas

| Criterio (prompt maestro §15) | Métrica | Prueba |
|---|---|---|
| Registrar ventas correctamente | 0 diferencias de totales; Σ líneas = cabecera | T03, T05–T07 ✔; propiedades de dinero (F2-01) |
| Evitar duplicados al sincronizar | 0 duplicados con reenvíos × 10 | T08, T21–T24 ✔; caos §5 |
| Mantener el aislamiento entre negocios | 0 lecturas o escrituras cruzadas | T01, T02, T36–T40 ✔; pruebas de autorización por endpoint |
| Conservar la trazabilidad del inventario | Stock = Σ kardex; movimiento con autor y motivo | T04, T09, T10, T19 ✔; invariante en caos |
| Recuperarse de interrupciones | 0 pérdidas tras matar la app en cualquier punto | Caos §5 (C3, C4) |
| Calcular importes consistentemente | Dart = Python en el 100 % de los vectores | `money_vectors.json` (F2-01) |
| Interfaz comprensible | ≥ 7/8 sin ayuda; SUS ≥ 70; ≤ 5 min hasta la primera venta | Usabilidad Fase 3 |
| Arquitectura verificable | 0 violaciones de límites de módulos | `import-linter` en CI |
| Proteger datos y credenciales | 0 secretos en el repositorio; 0 datos personales en logs | gitleaks; prueba de logs |
| Separar ventas de comprobantes válidos | 0 "aceptado" sin evidencia; 0 envíos de producción fuera de producción | T26, T27 ✔; pruebas del worker de facturación |

## 4. Pruebas de propiedades (ejemplos)

- **Dinero**: para cualquier lista de líneas válida, `subtotal + tax = total`; todo importe tiene 2
  decimales; el descuento nunca produce un importe negativo; el resultado es idéntico en Dart y
  Python.
- **Stock**: para cualquier secuencia de movimientos, `stock_levels = Σ quantity`; anular una venta
  restituye exactamente lo descontado.
- **Fiado**: para cualquier secuencia de ventas al fiado, abonos y anulaciones,
  `saldo = Σ ventas no anuladas − Σ abonos confirmados`.
- **Costo promedio**: está entre el mínimo y el máximo de los costos de entrada (con stock previo ≥ 0).
- **Estados de comprobante**: ninguna secuencia de eventos lleva a `accepted` sin evidencia; los
  estados terminales no retroceden.

## 5. Batería de caos de sincronización

Simulador con D dispositivos (2–10) por negocio que generan operaciones aleatorias válidas (ventas,
cobros, anulaciones, ajustes, conteos y ediciones de catálogo) con red intermitente. Al final
sincronizan todos y se verifican los invariantes.

| ID | Perturbación | Invariante |
|---|---|---|
| C1 | Cada lote se envía de 1 a 5 veces | 0 duplicados (Σ ventas del servidor = Σ ventas generadas) |
| C2 | Respuestas perdidas (30 %) | Mismo resultado que sin pérdidas |
| C3 | Se "mata" la app entre escribir y `acked`, y entre `sending` y la respuesta | 0 pérdidas; outbox recuperada |
| C4 | Reinicio del servidor a mitad de lote | Atomicidad por operación; reintento correcto |
| C5 | Partición de 1–30 días simulados para un dispositivo | Convergencia tras reconectar |
| C6 | Relojes desfasados ±3 h | Orden por `device_seq`; alerta de desfase; reportes por día correctos |
| C7 | Dispositivo revocado a mitad de la partición | Se aceptan solo las operaciones previas a la revocación |
| C8 | Ediciones concurrentes de precio con distintos roles | Resultado según §5.4; descartes auditados |
| C9 | Conteos concurrentes con ventas | Delta correcto y `needs_review` cuando corresponde |
| C10 | Versión N−1 del protocolo mezclada con N | Ambas se aplican; N−2 → 426 sin pérdida local |

Invariantes globales: stock = Σ kardex; saldos de fiado correctos; Σ cobros por caja = esperado;
cada operación generada tiene exactamente un `sync_events`; todos los dispositivos ven el mismo
estado consolidado.

**Criterio de salida de Fase 2**: 1 000 ejecuciones aleatorias con semillas registradas, 0 fallos.

## 6. Facturación

- Pruebas del dominio y de la máquina de estados (todas las transiciones permitidas y prohibidas).
- `FakeBillingProvider` programable: acepta, observa, rechaza, *timeout*, respuesta duplicada,
  aceptación tardía y "no encontrado".
- Prueba clave: *timeout* → `unknown` → **consulta antes de reenviar** → nunca dos emisiones del
  mismo número.
- Pruebas de contrato del adaptador real **solo en el ambiente de pruebas del proveedor**, en staging
  y bajo demanda.
- Salvaguardas de entorno: T27 ✔ + prueba del adaptador que se niega a usar URL de producción + escaneo de configuración.
- E2E en staging: venta → boleta → evidencia → PDF → compartir.

## 7. Datos de prueba

Solo sintéticos (generadores con semilla). Nunca datos reales de clientes en desarrollo o CI. Para
el conjunto de evaluación de IA (Fase 6): comprobantes reales **anonimizados** con consentimiento.

## 8. Entornos y CI

- Cada PR: lint, tipos, pruebas unitarias y de integración, `check_schema.sh`, `check_docs.sh`,
  `import-linter`, escaneo de seguridad. Duración objetivo ≤ 10 min.
- Nightly: caos (200 semillas), rendimiento en emulador, contrato con OpenAPI.
- Antes de cada versión: caos (1 000 semillas), dispositivo físico de referencia, E2E de facturación en staging.

## 9. Resultados actuales

Ver [PROGRESS.md](PROGRESS.md). Fase 0: esquema borrador con 41/41 aserciones en verde.
