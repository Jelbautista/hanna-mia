# Informe de cierre de Fase 0 — MiNegocio AI

Fecha: 2026-11-19 · Estado: **entregables completos, pendientes de revisión**. No se inicia la
implementación del núcleo comercial hasta revisar este informe y responder las preguntas
bloqueantes (§5).

## 1. Trabajo completado

| # | Acción pedida (prompt maestro §16) | Resultado | Documento |
|---|---|---|---|
| 1 | Inspeccionar el entorno | Repositorio con un proyecto ajeno → subdirectorio `minegocio-ai/`; inventario de herramientas | [PROGRESS](PROGRESS.md) |
| 2 | Crear la estructura documental | 14 documentos obligatorios + 12 complementarios | [README](../README.md) |
| 3 | PRD completo | Problema, personas, objetivos medibles, 20 RF, 15 RNF, definiciones financieras, riesgos | [PRD](requirements/PRD.md) |
| 4 | Arquitectura C4 | Contexto, contenedores, componentes de la API y de la app | [C4](architecture/C4.md), [SYSTEM_ARCHITECTURE](architecture/SYSTEM_ARCHITECTURE.md) |
| 5 | Modelo de datos | 29 tablas (22 pedidas + 7 de soporte), **SQL ejecutable probado** | [DATABASE_DESIGN](architecture/DATABASE_DESIGN.md), `db/phase0/` |
| 6 | Flujo de primera venta | Onboarding de 5 preguntas, venta rápida en 3 toques, venta guiada, glosario | [FIRST_SALE_FLOW](ux/FIRST_SALE_FLOW.md) |
| 7 | Estrategia de sincronización | Operaciones de dominio idempotentes, conflictos por dominio, 12 escenarios multi-dispositivo | [SYNC_STRATEGY](architecture/SYNC_STRATEGY.md) |
| 8 | Límites de integración SUNAT | 23 reglas clasificadas por fuente y estado; `BillingProvider`; máquina de estados | [INTEGRATION_PLAN](sunat/INTEGRATION_PLAN.md) |
| 9 | Backlog priorizado | Fases 0–6 con dependencias, historias y criterios de salida | [BACKLOG](requirements/BACKLOG.md) |
| 10 | Criterios de aceptación y riesgos | 73 historias con CA (las críticas en Gherkin); matriz criterio → prueba | [USER_STORIES](requirements/USER_STORIES.md), [TEST_PLAN](TEST_PLAN.md) |
| 11 | Informe de decisiones y preguntas | Este documento | — |

Complementarios: [MODULE_SPECS](requirements/MODULE_SPECS.md) (16 módulos × 12 aspectos),
[API_CONTRACTS](architecture/API_CONTRACTS.md), [SEQUENCE_DIAGRAMS](architecture/SEQUENCE_DIAGRAMS.md)
(8 flujos), [THREAT_MODEL](security/THREAT_MODEL.md) (22 amenazas STRIDE + protección de datos),
[ROADMAP](ROADMAP.md) y [ADR-001 a ADR-008](decisions/README.md).

## 2. Decisiones técnicas principales

| Decisión | Motivo principal | ADR |
|---|---|---|
| Monolito modular (API + worker) con límites verificados en CI | Transacciones ACID entre venta, inventario y cobro; equipo pequeño | 001 |
| Sincronización por **operaciones de dominio** con `op_id` y `device_seq`, no por filas | Idempotencia, auditoría y reglas de negocio iguales en línea y sin conexión | 002 |
| Sin "última escritura gana" en dinero, inventario ni comprobantes; solo en preferencias | Requisito del prompt; evitar pérdida silenciosa | 002 |
| Dinero en decimal exacto; precio con IGV incluido; impuesto por línea; vectores compartidos Dart/Python | Cero descuadres de céntimos | 003 |
| Facturación detrás de `BillingProvider`; primer proveedor externo PSE/OSE; comprobantes solo desde el servidor | Menor riesgo regulatorio y tiempo al mercado | 004 |
| Multiempresa por fila + **FK compuestas** + RLS `FORCE` | Tres barreras contra fugas entre negocios | 005 |
| IA solo propone; el humano confirma; sin herramientas de escritura | Control del usuario y seguridad | 006 |
| Cola de tareas en PostgreSQL (outbox transaccional) | Atomicidad sin un *broker* adicional | 007 |
| Ventas como hechos inmutables; stock negativo permitido con alerta | La venta sin conexión ya ocurrió; corregir con compensación | 008 |
| Reglas críticas reforzadas en la BD (totales, evidencia, producción, inmutabilidad) | Defensa en profundidad verificable | — |

## 3. Pruebas ejecutadas y resultados

| Verificación | Resultado real |
|---|---|
| `tools/check_schema.sh` contra PostgreSQL 16.15 | 29 tablas; **41/41 aserciones PASS** |
| `tools/check_diagrams.sh` (mermaid-cli 11.4.2 + Chromium) | **15/15 diagramas renderizados** |
| `tools/check_docs.sh` | 27 archivos .md; **14/14 documentos obligatorios**; **126 enlaces internos válidos**; 15 bloques Mermaid bien formados |

No hay pruebas de aplicación porque todavía no hay código de aplicación (Fase 0).

## 4. Problemas encontrados

1. **Repositorio compartido** con un proyecto ajeno (sitio de panetón). Mitigación temporal:
   subdirectorio aislado. Decisión en Q1.
2. **Acceso bloqueado a sunat.gob.pe y cpe.sunat.gob.pe** desde la sesión. La normativa se tomó de
   fragmentos oficiales indexados y de fuentes secundarias, todo marcado con su estado. Hay que
   repetir la verificación con acceso directo y con un especialista (P0-11).
3. **Flutter/Dart y el demonio de Docker no están disponibles** en este entorno. La Fase 1 necesita
   un entorno con Flutter SDK y Docker (o una configuración de entorno que los instale).
4. Tres defectos del borrador detectados **por las propias pruebas** y corregidos (ver
   [PROGRESS](PROGRESS.md)).

## 5. Preguntas bloqueantes

| ID | Pregunta | Bloquea | Recomendación |
|---|---|---|---|
| **Q1** | ¿Se crea un **repositorio propio** para MiNegocio AI? Hoy vive en `hanna-mia/minegocio-ai/` junto a un sitio ajeno | Fase 1 (monorepo y CI) | Sí: repositorio nuevo `minegocio-ai`; mover `minegocio-ai/` conservando el historial |
| **Q2** | Equipo, dedicación y fecha objetivo del piloto | Calibración del roadmap | Confirmar 2–3 personas; recalibrar al cerrar la Fase 1 |
| **Q3** | **Proveedor de facturación** (PSE/OSE): ¿hay preferencia o contrato? ¿Quién gestiona la cotización? ¿Cuál es la entidad legal de MiNegocio? | Fase 4 | Cotizar 2–3 proveedores con los criterios del plan SUNAT §3 durante las Fases 1–2 |
| **Q4** | Canal y proveedor de **códigos de verificación** (SMS o WhatsApp) y presupuesto por código | Fase 1 (F1-07; se avanza con un proveedor *fake*) | WhatsApp como canal principal y SMS como respaldo, sujeto a costo |
| **Q5** | **Nube y región** (residencia de datos, flujo transfronterizo según la Ley 29733) | Fase 5 (staging desde la Fase 2) | Decidir tras la consulta legal Q7; mientras tanto, diseño agnóstico (contenedores + PostgreSQL gestionado + S3) |
| **Q6** | **Planes y precios**; pasarela de cobro de suscripciones | Fase 5 | Validar la disposición a pagar en entrevistas P0-12 |
| **Q7** | ¿Quién hace la **validación tributaria** (lista de 11 puntos del plan SUNAT §9) y la **legal de privacidad** (THREAT_MODEL §7)? | Fase 4 y producción | Contador/asesor tributario y abogado de datos personales antes de la Fase 4 |
| **Q8** | Acceso a **8–10 comerciantes** para descubrimiento y usabilidad; **dispositivo de referencia** (modelo Android de gama baja concreto) | Metas de rendimiento y usabilidad | Elegir un modelo con 2 GB de RAM muy vendido en el segmento; comprar 1–2 unidades para CI manual |

No bloqueantes (se deciden en su fase): tecnología del panel web (Fase 5), base de nombres por
código de barras (licencia), conciliación automática con Yape/Plin (¿existe una API para
comercios?), librería de cola (ADR-007) y proveedor de IA (Fase 6).

**Observación**: el negocio de este mismo repositorio (preventa de panetones artesanales) podría
servir como **piloto temprano** del rubro "Panadería" si se desea. Es una sugerencia, no un supuesto.

## 6. Riesgos pendientes (técnicos y de proyecto)

| ID | Riesgo | Prob. | Impacto | Mitigación / próximo paso |
|---|---|---|---|---|
| R1 | La sincronización tiene defectos sutiles (duplicados o pérdidas) | Media | Crítico | Batería de caos de 1 000 semillas como criterio de salida de la Fase 2; idempotencia ya reforzada en la BD |
| R2 | Normativa SUNAT mal interpretada o cambiante | Alta | Alto | Reglas como datos versionados; P0-11; revisión mensual de normas; proveedor externo |
| R3 | Rendimiento insuficiente en gama baja | Media | Alto | Presupuesto en CI y dispositivo de referencia desde la Fase 1 |
| R4 | Costo variable (OTP, comprobantes, IA) mayor que el precio | Media | Alto | Medir el costo unitario desde el piloto; cupos; límites contra abuso |
| R5 | Adopción: carga inicial de productos | Alta | Alto | Plantillas, producto libre, importación; usabilidad en la Fase 3 |
| R6 | Incumplimiento de la normativa de datos personales | Media | Alto | Q7 antes de producción; minimización desde el diseño |
| R7 | Dependencia de un solo proveedor de facturación | Media | Medio | `BillingProvider` + segundo proveedor evaluado |
| R8 | Entorno de desarrollo incompleto (sin Flutter ni Docker aquí) | Alta | Medio | Configurar un entorno con Flutter SDK y Docker antes de la Fase 1 |

## 7. Siguiente fase recomendada

**Fase 1 — Fundamentos**, tras: (a) revisar este informe, (b) responder Q1 (repositorio) y
(c) preparar un entorno con Flutter SDK y Docker. Q2–Q8 pueden resolverse en paralelo durante la
Fase 1 sin bloquearla, salvo Q4 para pasar del OTP *fake* a uno real.

Primer incremento propuesto (≈ 1 semana): F1-01 monorepo + F1-02 Docker Compose + F1-03 CI con
`check_schema.sh`, `check_docs.sh` y `check_diagrams.sh` + F1-04 núcleo del backend
(`Money`/uuid7/errores) + F1-05 primeras migraciones Alembic con las aserciones portadas a pytest.
