# Bitácora de avance — MiNegocio AI

Cada entrada registra el trabajo hecho, la **evidencia** (comando y resultado real) y los
problemas encontrados. Nunca se registra un resultado que no se haya ejecutado.

---

## 2026-11-19 — Fase 0: planificación integral

### Trabajo completado

- Inspección del entorno: el repositorio `hanna-mia` contiene un sitio estático ajeno al producto
  (preventa de panetón). Para no mezclar proyectos, MiNegocio AI se creó en `minegocio-ai/` (ver Q1
  en el [informe](PHASE0_REPORT.md)).
- Herramientas disponibles: Python 3.13, uv, Poetry, Node 22, PostgreSQL 16 (cliente y servidor) y
  Chromium. **No disponibles**: Flutter/Dart SDK y demonio de Docker (la CLI existe, el demonio no
  responde).
- Investigación normativa SUNAT y de protección de datos (búsqueda web; el acceso directo a
  `sunat.gob.pe` y `cpe.sunat.gob.pe` está bloqueado por la red de la sesión).
- Documentos creados: los 14 obligatorios + especificación de módulos, contratos API, diagramas de
  secuencia, flujo de primera venta, 8 ADR e informe de Fase 0.
- Esquema relacional borrador **ejecutable** (29 tablas) con batería de pruebas.

### Evidencia

| Verificación | Comando | Resultado |
|---|---|---|
| Esquema de BD | `tools/check_schema.sh` (PostgreSQL 16.15 local) | **29 tablas creadas; 41/41 aserciones PASS** (T00–T40 + FIN) |
| Documentación | `tools/check_docs.sh` | **14/14 documentos obligatorios; 126 enlaces internos válidos**; 27 archivos .md |
| Diagramas | `tools/check_diagrams.sh` (mermaid-cli 11.4.2 + Chromium) | **15/15 diagramas renderizados sin error** |

Aserciones del esquema (resumen): aislamiento por FK compuestas (T01–T02) y RLS (T36–T40);
cálculo de IGV incluido y stock negativo visible (T03–T04); cuadre de totales (T05–T07);
idempotencia del kardex (T08); kardex append-only y motivo obligatorio (T09–T10); inmutabilidad y
anulación compensatoria de ventas y cobros (T11–T20); idempotencia de sincronización (T21–T25);
comprobantes: aceptación solo con evidencia, bloqueo de producción, factura con RUC, un comprobante
vigente por venta, inmutabilidad, estados terminales, NC con referencia, sin borrado (T26–T34);
auditoría inmutable (T35).

### Problemas encontrados y corregidos (detectados por las pruebas)

1. `check_sale_totals()` usaba `CASE … NEW.sale_id …`: PL/pgSQL resuelve el campo aunque la rama no
   se ejecute y fallaba en la tabla `sales`. **Corregido** con `IF/ELSE`.
2. Los códigos de error `P0002`, `P0003` y `P0004` están reservados (`no_data_found`,
   `too_many_rows`, `assert_failure`); `assert_failure` no se puede capturar con `WHEN OTHERS`.
   **Corregido**: clase propia `MN001`–`MN004`, documentada en el encabezado del esquema.
3. Tres diagramas de secuencia no renderizaban porque `;` separa sentencias en Mermaid.
   **Corregido** (se usa `·`).

### Pendiente

- Revisión de los entregables por el responsable del producto (P0-09).
- Respuestas a las preguntas bloqueantes Q1–Q8.
- Validación tributaria (P0-11) y legal (privacidad) por especialistas.
- Entrevistas con comerciantes (P0-12).
