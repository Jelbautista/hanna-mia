# MiNegocio AI

> **"Dime qué vendes y te ayudo a organizarlo".**

Plataforma de gestión comercial *offline-first* para microempresas y pequeños negocios del Perú:
ventas, compras, inventario, cobros, comprobantes electrónicos y resultados, desde un celular Android.

**Estado actual: Fase 0, planificación.** Todavía no hay código de aplicación. Este directorio tiene
los entregables de planificación y un esquema de base de datos borrador ya validado contra PostgreSQL.

> Nota de ubicación: el proyecto vive temporalmente en `minegocio-ai/` dentro del repositorio
> `hanna-mia`, que contiene un sitio web ajeno a este producto. Mudarlo a un repositorio propio es una
> de las preguntas bloqueantes (ver [`docs/PHASE0_REPORT.md`](docs/PHASE0_REPORT.md)).

## Mapa de documentos

| Documento | Contenido |
|---|---|
| [docs/PHASE0_REPORT.md](docs/PHASE0_REPORT.md) | **Empiece aquí.** Informe de decisiones técnicas, riesgos y preguntas bloqueantes |
| [docs/requirements/PRD.md](docs/requirements/PRD.md) | Requisitos de producto, personas, métricas y alcance |
| [docs/requirements/MODULE_SPECS.md](docs/requirements/MODULE_SPECS.md) | Especificación de los 16 módulos (A–P) |
| [docs/requirements/USER_STORIES.md](docs/requirements/USER_STORIES.md) | Historias de usuario con criterios de aceptación |
| [docs/requirements/BACKLOG.md](docs/requirements/BACKLOG.md) | Backlog priorizado por fase |
| [docs/architecture/SYSTEM_ARCHITECTURE.md](docs/architecture/SYSTEM_ARCHITECTURE.md) | Arquitectura del sistema y justificación del stack |
| [docs/architecture/C4.md](docs/architecture/C4.md) | Diagramas C4 (contexto, contenedores, componentes) |
| [docs/architecture/DATABASE_DESIGN.md](docs/architecture/DATABASE_DESIGN.md) | Modelo de datos (servidor PostgreSQL y dispositivo SQLite) |
| [docs/architecture/SYNC_STRATEGY.md](docs/architecture/SYNC_STRATEGY.md) | Sincronización offline-first y resolución de conflictos |
| [docs/architecture/SEQUENCE_DIAGRAMS.md](docs/architecture/SEQUENCE_DIAGRAMS.md) | Diagramas de secuencia de los flujos críticos |
| [docs/architecture/API_CONTRACTS.md](docs/architecture/API_CONTRACTS.md) | Contratos de la API REST |
| [docs/ux/FIRST_SALE_FLOW.md](docs/ux/FIRST_SALE_FLOW.md) | Onboarding y flujo de primera venta |
| [docs/sunat/INTEGRATION_PLAN.md](docs/sunat/INTEGRATION_PLAN.md) | Plan de integración SUNAT y estado de verificación normativa |
| [docs/security/THREAT_MODEL.md](docs/security/THREAT_MODEL.md) | Modelo de amenazas (STRIDE) y controles |
| [docs/decisions/](docs/decisions/README.md) | Registro de decisiones arquitectónicas (ADR) |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Fases 0–6 con criterios de salida |
| [docs/TEST_PLAN.md](docs/TEST_PLAN.md) | Estrategia de pruebas y criterios de calidad |
| [docs/PROGRESS.md](docs/PROGRESS.md) | Bitácora de avance con evidencias |

## Stack decidido (resumen)

| Capa | Tecnología | ADR |
|---|---|---|
| App móvil | Flutter + Dart, Android primero; Riverpod; Drift (SQLite + SQLCipher) | [ADR-001](docs/decisions/ADR-001.md) |
| Backend | Python 3.12+, FastAPI, SQLAlchemy 2, Alembic, Pydantic v2 | [ADR-001](docs/decisions/ADR-001.md) |
| Base de datos | PostgreSQL 16+ con Row Level Security | [ADR-005](docs/decisions/ADR-005.md) |
| Tareas asíncronas | Cola sobre PostgreSQL (sin Redis al inicio) | [ADR-007](docs/decisions/ADR-007.md) |
| Sincronización | Bitácora de operaciones de dominio idempotentes | [ADR-002](docs/decisions/ADR-002.md) |
| Facturación | Interfaz `BillingProvider`; PSE/OSE como primer proveedor | [ADR-004](docs/decisions/ADR-004.md) |
| Dinero | Decimal exacto; nunca coma flotante | [ADR-003](docs/decisions/ADR-003.md) |
| IA | Capa opcional con confirmación humana obligatoria | [ADR-006](docs/decisions/ADR-006.md) |

## Verificación disponible hoy

```bash
# Requiere PostgreSQL 16+ local (o PGHOST/PGUSER de un servidor de pruebas)
tools/check_schema.sh   # carga db/phase0/schema_draft.sql y ejecuta 41 aserciones
tools/check_docs.sh     # verifica documentos obligatorios y enlaces internos
tools/check_diagrams.sh # renderiza los 15 diagramas Mermaid (Node 18+ y Chromium)
```

## Estructura prevista (Fase 1)

```
minegocio-ai/
  apps/mobile/            Flutter (feature-first)
  services/api/           FastAPI (monolito modular)
  db/phase0/              esquema borrador y pruebas (se migrará a Alembic)
  docs/                   documentación viva
  infra/                  docker-compose, CI/CD
  tools/                  scripts de verificación
```
