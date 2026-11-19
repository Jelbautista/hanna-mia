# Arquitectura del sistema — MiNegocio AI

Versión 0.1 · Fase 0 · Diagramas en [C4.md](C4.md) · Decisiones en [../decisions/](../decisions/README.md)

## 1. Vista general

```
┌──────────────────────────┐        HTTPS (JSON)        ┌───────────────────────────────────────┐
│ App Android (Flutter)    │ ─────────────────────────▶ │ API MiNegocio (FastAPI, monolito       │
│  · UI feature-first      │   push de operaciones /    │ modular)                               │
│  · Riverpod (estado)     │   pull incremental         │  · módulos de dominio A–P              │
│  · Drift/SQLite cifrado  │ ◀───────────────────────── │  · worker de tareas (mismo código)     │
│  · Outbox persistente    │                            │  · PostgreSQL 16 (RLS)                 │
└──────────────────────────┘                            │  · almacenamiento de objetos (PDF/CDR) │
                                                        └──────────┬────────────────────────────┘
                                                                   │ BillingProvider (HTTPS)
                                                                   ▼
                                                       PSE / OSE / SEE-Del Contribuyente → SUNAT
```

Principio rector: **el dispositivo es la fuente de verdad de lo que ocurrió en el mostrador; el
servidor es la fuente de verdad de lo que ya se consolidó** (catálogo compartido, stock consolidado,
comprobantes tributarios, suscripción). Los comprobantes electrónicos **solo** los emite el servidor.

## 2. Por qué un monolito modular

| Alternativa | Ventaja | Por qué no ahora |
|---|---|---|
| Microservicios | Escalado independiente | Equipo pequeño, transacciones financieras entre módulos (venta + inventario + cobro) que exigirían sagas; costo operativo alto |
| Backend-as-a-Service (Firebase, Supabase) | Rapidez inicial | Lógica financiera e idempotencia de dominio quedarían en el cliente o en funciones dispersas; RLS sola no expresa reglas de negocio; dependencia de proveedor en datos tributarios |
| **Monolito modular** | Una transacción ACID por operación de dominio, un despliegue, límites claros entre módulos | — |

Los módulos se comunican solo por **interfaces públicas** (servicios de aplicación) y **eventos de
dominio internos**. Ningún módulo lee tablas de otro directamente. Esto se verifica en CI con
`import-linter` (contratos de capas e independencia). Si un módulo necesita extraerse, por ejemplo
facturación, el límite ya existe.

Detalle de la decisión: [ADR-001](../decisions/ADR-001.md).

## 3. Backend

### 3.1 Estructura de código

```
services/api/
  app/
    main.py                  # composición: routers, middlewares, OpenAPI
    core/                    # config, seguridad, db, errores (RFC 9457), logging, ids (uuid7), money
    shared/                  # kernel compartido: Money, Quantity, BusinessId, eventos base
    modules/
      identity/              # A
      businesses/            # B
      onboarding/            # C
      catalog/               # D
      purchasing/            # E
      inventory/             # F
      sales/                 # G
      payments/              # H
      customers/             # I
      billing/               # J  (BillingProvider y adaptadores)
      finance/               # K  (caja, gastos, reportes)
      dashboard/             # L
      sync/                  # M
      subscriptions/         # N
      admin/                 # O
      assistant/             # P
        api.py               #   routers FastAPI (capa HTTP)
        schemas.py           #   Pydantic v2 (contratos)
        service.py           #   casos de uso; única puerta pública del módulo
        domain.py            #   entidades, reglas puras, sin I/O
        repository.py        #   SQLAlchemy 2 (async)
        events.py            #   eventos que publica/consume
        tests/
    worker.py                # proceso de tareas asíncronas (misma base de código)
  migrations/                # Alembic
```

### 3.2 Capas y reglas

1. `domain.py` no importa FastAPI, SQLAlchemy ni nada de I/O. Ahí viven las reglas de dinero, stock
   y estados, que se prueban con pruebas unitarias y de propiedades (Hypothesis).
2. `service.py` abre **una transacción por caso de uso**, fija `SET LOCAL app.business_id`, invoca
   el dominio, persiste y registra eventos en la tabla outbox del servidor en la misma transacción.
3. `api.py` solo traduce HTTP ⇄ caso de uso; la autorización se declara por endpoint
   (`requires("sales.create")`) y se verifica también por recurso (pertenencia al negocio).

### 3.3 Tareas asíncronas

Cola persistida en PostgreSQL con `SELECT … FOR UPDATE SKIP LOCKED`
([ADR-007](../decisions/ADR-007.md)). Usos: envío y consulta de comprobantes, generación de PDF,
recálculo de agregados del dashboard, notificaciones y tareas de IA. Ventaja: el evento y la tarea
se guardan en la **misma transacción** que la operación de negocio, sin un *broker* extra que pueda
desincronizarse. Se migrará a un *broker* dedicado solo si las métricas de cola lo exigen.

### 3.4 Errores

Formato `application/problem+json` (RFC 9457) con `code` estable legible por la app
(`sale.totals_mismatch`, `sync.op_conflict`, `billing.provider_unavailable`). La app traduce
`code` a mensajes en lenguaje simple; nunca muestra trazas.

## 4. App móvil

### 4.1 Estructura feature-first

```
apps/mobile/lib/
  core/            # tema, accesibilidad, router, money (Decimal), ids (uuid7), errores
  data/
    db/            # Drift: tablas, DAOs, migraciones locales, outbox
    sync/          # SyncEngine: push, pull, backoff, monitoreo
    api/           # cliente HTTP (dio), autenticación, refresh
  features/
    onboarding/  catalog/  sale_quick/  sale_guided/  payments/  customers/
    purchases/   inventory/  cash/  expenses/  dashboard/  invoices/  settings/
      presentation/   # widgets y pantallas
      application/    # providers Riverpod / notifiers (casos de uso)
      domain/         # reglas puras compartidas con pruebas
```

### 4.2 Reglas

- **Escritura local primero**: cada caso de uso escribe en SQLite y en la `outbox` en **una sola
  transacción** Drift. La UI nunca espera a la red.
- **Lectura reactiva**: las pantallas observan *streams* de Drift; el sincronizador actualiza tablas
  y la UI se refresca sola.
- **Riverpod**: estado inmutable, *providers* con alcance por negocio activo (al cambiar de negocio
  se destruye todo el árbol de estado, lo que evita filtraciones de datos entre negocios).
- **Cifrado**: SQLCipher; clave aleatoria de 256 bits guardada con Android Keystore
  (`flutter_secure_storage`).
- **Reglas de dinero compartidas**: el cálculo de líneas e impuestos se implementa en Dart y en
  Python con **los mismos vectores de prueba** (`docs/architecture/money_vectors.json`, Fase 2) para
  garantizar resultados idénticos al céntimo.

### 4.3 Presupuesto de rendimiento (CI)

| Métrica | Presupuesto |
|---|---|
| APK por ABI | ≤ 30 MB |
| Arranque en frío (dispositivo de referencia) | ≤ 3 s |
| Registro de venta local p95 | ≤ 300 ms |
| Memoria en uso típico | ≤ 200 MB |

## 5. Datos

- **Servidor**: PostgreSQL 16+, esquema en [DATABASE_DESIGN.md](DATABASE_DESIGN.md), borrador
  ejecutable en `db/phase0/schema_draft.sql` con pruebas en `db/phase0/schema_checks.sql`.
- **Dispositivo**: SQLite (Drift) con subconjunto del esquema + tablas de sincronización
  (`outbox`, `sync_state`, `pending_conflicts`).
- **Objetos**: almacenamiento compatible con S3 para PDF, XML firmados y constancias (CDR) con
  versionado y bloqueo de objetos (WORM) para evidencia tributaria.

## 6. Seguridad (resumen)

Detalle en [THREAT_MODEL.md](../security/THREAT_MODEL.md).

- Autenticación: celular + código de verificación de un solo uso; *access token* JWT de 15 min
  y *refresh token* rotativo ligado al dispositivo; PIN local para desbloqueo rápido.
- Autorización: rol por membresía + permisos por acción + pertenencia del recurso al negocio,
  con RLS como segunda barrera.
- Secretos: gestor de secretos del proveedor de nube; nunca en el repositorio ni en la app.
- Credenciales tributarias: con un PSE/OSE, MiNegocio **no custodia la Clave SOL** del comerciante.
  Si en el futuro se usa SEE-Del Contribuyente, los certificados se cifran con KMS (cifrado de sobre).

## 7. Entornos

| Entorno | Propósito | Facturación | Datos |
|---|---|---|---|
| `local` | Desarrollo (Docker Compose) | `FakeBillingProvider` únicamente | Sintéticos |
| `test` / CI | Pruebas automáticas | `FakeBillingProvider` | Sintéticos, efímeros |
| `staging` | Validación previa | Ambiente de pruebas (beta) del PSE/OSE | Sintéticos o anonimizados |
| `production` | Clientes reales | Proveedor real, **solo tras aprobación explícita** | Reales |

Controles contra emisión real fuera de producción (defensa en profundidad):

1. La configuración del proveedor de producción solo existe en el gestor de secretos de producción.
2. El adaptador valida al iniciar que `DEPLOY_ENV == "production"` antes de aceptar URL de producción.
3. La base de datos rechaza `invoices.environment = 'production'` si la instancia no está marcada
   como producción (trigger verificado por la prueba T27 de `schema_checks.sql`).
4. Prueba de CI que falla si existe una URL de producción conocida en configuración no productiva.

## 8. Infraestructura

- **Desarrollo**: Docker Compose con `api`, `worker`, `postgres`, `minio` (objetos) y `mailpit`.
- **Producción**: contenedores en un proveedor de nube con base de datos gestionada, copias
  automáticas y recuperación a un punto en el tiempo. **Proveedor y región por decidir** (pregunta
  bloqueante: residencia de datos y flujo transfronterizo según la normativa de datos personales).
- **HTTPS** obligatorio (TLS 1.2+), HSTS y certificados automáticos.
- **CI/CD** (GitHub Actions): lint, tipos (mypy estricto / `dart analyze`), pruebas, verificación del
  esquema, análisis de dependencias y secretos, construcción de imágenes y APK firmado. Despliegue a
  producción manual con aprobación.
- **Observabilidad**: logs JSON estructurados (structlog) sin datos personales, métricas y trazas
  OpenTelemetry, reporte de errores (Sentry o alternativa autoalojada), *dashboards* de sincronización
  y facturación con alertas.
- **Copias**: diarias completas + WAL continuo; restauración de prueba **mensual verificada**
  automáticamente (se restaura, se ejecutan consultas de conciliación y se registra la evidencia).

## 9. Atributos de calidad y tácticas

| Atributo | Táctica |
|---|---|
| Integridad financiera | Decimal exacto, totales verificados en BD, inmutabilidad + compensación, auditoría |
| Disponibilidad percibida | Offline-first: el servidor caído no detiene ventas |
| Idempotencia | `op_id` por operación, índices únicos de dominio, resultados guardados |
| Aislamiento | `business_id` en todo, FK compuestas, RLS, pruebas de acceso cruzado |
| Evolutividad | Monolito modular con contratos verificados, ADR, reglas tributarias como datos |
| Costo | Un solo motor de base de datos, cola en PostgreSQL, IA opcional con cupos |
