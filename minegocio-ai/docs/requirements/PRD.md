# PRD — MiNegocio AI

| Campo | Valor |
|---|---|
| Versión | 0.1 (Fase 0, borrador para revisión) |
| Fecha | 2026-11-19 |
| Estado | En revisión; las metas numéricas son **hipótesis iniciales** que se validarán con pilotos |
| Documentos relacionados | [MODULE_SPECS](MODULE_SPECS.md) · [USER_STORIES](USER_STORIES.md) · [BACKLOG](BACKLOG.md) · [FIRST_SALE_FLOW](../ux/FIRST_SALE_FLOW.md) |

## 1. Resumen

MiNegocio AI convierte un celular Android en la herramienta con la que un pequeño comerciante
peruano registra ventas, controla su mercadería, cobra (efectivo, Yape, Plin, tarjeta), emite
comprobantes electrónicos cuando le corresponde y entiende cuánto gana. Funciona **sin internet** y
se sincroniza cuando hay señal.

Propuesta de valor: **"Dime qué vendes y te ayudo a organizarlo"**. El sistema se configura a partir
del rubro del negocio, no al revés.

## 2. Problema

1. Muchos pequeños negocios registran ventas en cuaderno o no las registran. No saben su margen
   real ni cuánto les deben.
2. Las herramientas disponibles suelen pensar en un contador: formularios largos, términos como
   "base imponible" o "kardex" y obligación de estar en línea.
3. La conectividad en mercados, galerías y zonas periurbanas es intermitente. Una app que se cae sin
   señal pierde ventas y confianza.
4. Las obligaciones tributarias cambian según el régimen (Nuevo RUS, RER, Régimen MYPE Tributario,
   Régimen General). Cumplirlas sin ayuda es difícil, y un error genera multas.
5. Varias personas usan el mismo negocio (dueña, hija, ayudante), a veces en varios celulares a la
   vez, y sin control aparecen faltantes de caja y de mercadería.

## 3. Objetivos y no-objetivos

### Objetivos (MVP, Fases 1–4)

| ID | Objetivo | Métrica | Meta inicial (hipótesis) |
|---|---|---|---|
| O1 | Llegar rápido a la primera venta | Mediana del tiempo entre instalación y primera venta registrada | ≤ 5 min |
| O2 | Que vender sea más rápido que anotar | Toques para vender 1 producto favorito en efectivo exacto | ≤ 3 toques |
| O3 | No perder ni duplicar datos | Ventas duplicadas o perdidas en pruebas de caos de sincronización | 0 |
| O4 | Uso sostenido | Negocios activos a 30 días (≥ 1 venta/semana) | ≥ 35 % de activados |
| O5 | Confianza en los números | Diferencia entre caja esperada y contada atribuible al sistema | 0 (toda diferencia es explicable con movimientos) |
| O6 | Cumplimiento tributario sin fricción | Comprobantes aceptados sin intervención / emitidos | ≥ 98 % en piloto |
| O7 | Rendimiento en gama baja | Arranque en frío en dispositivo de referencia | ≤ 3 s |

### No-objetivos (explícitamente fuera del MVP)

- Contabilidad completa, libros electrónicos o declaraciones mensuales (se exportan datos para el contador).
- Registros electrónicos SIRE (se evalúa como integración posterior).
- Planillas y recursos humanos.
- Tienda en línea, delivery o marketplace.
- Cobros integrados con pasarela (Yape/Plin/tarjeta se **registran**, no se procesan).
- iOS y web de operación (solo panel administrativo web en Fase 5).
- Rubros regulados con requisitos sanitarios específicos (por ejemplo, farmacias) hasta validarlos.
- Guías de remisión electrónicas.

## 4. Usuarios y personas

| Persona | Perfil | Necesidad principal | Restricciones |
|---|---|---|---|
| **Rosa** (dueña de bodega) | 48 años, Lima periférica, Nuevo RUS, Android gama baja (2–3 GB RAM), usa WhatsApp y Yape | Saber cuánto vendió, qué le falta reponer y quién le debe | Baja alfabetización digital; poco tiempo; datos móviles limitados |
| **Lucía** (ayudante/cajera) | 22 años, hija de Rosa, atiende por la tarde en su propio celular | Cobrar rápido sin equivocarse | No debe poder anular ventas ni ver ganancias sin permiso |
| **Carlos** (ferretero) | 38 años, Arequipa, Régimen MYPE Tributario, emite boletas y facturas | Emitir comprobantes desde la venta, controlar miles de productos con código de barras | Clientes empresa piden factura al momento |
| **Contador externo** | Atiende 20–60 microempresas | Recibir ventas, compras y comprobantes ordenados | Solo lectura; exportaciones |
| **Soporte MiNegocio** | Equipo interno | Diagnosticar problemas de sincronización y facturación | Acceso mínimo, auditado y con consentimiento |

## 5. Alcance funcional

Los 16 dominios (A–P) se especifican en [MODULE_SPECS.md](MODULE_SPECS.md). Resumen por fase:

| Fase | Dominios |
|---|---|
| 1 Fundamentos | A Identidad y roles · B Negocios y establecimientos |
| 2 MVP comercial | D Productos · E Compras · F Inventario · G Ventas · H Cobros · I Clientes y fiado · K Caja y gastos · M Sincronización |
| 3 Experiencia | C Onboarding · L Dashboard · K Reportes |
| 4 Facturación | J SUNAT |
| 5 SaaS | N Suscripciones · O Panel administrativo |
| 6 IA | P Asistente (voz, imágenes, análisis) |

## 6. Requisitos funcionales clave

Cada requisito tiene historias y criterios de aceptación en [USER_STORIES.md](USER_STORIES.md).

| ID | Requisito | Criterio medible |
|---|---|---|
| RF-01 | Registro e inicio de sesión con número de celular y código de verificación | Alta completa en ≤ 60 s con señal 3G; sin contraseña obligatoria |
| RF-02 | Configuración guiada por rubro (5 preguntas) | 100 % de las preguntas se pueden omitir; plantilla aplicada en ≤ 2 s |
| RF-03 | Alta de productos manual, por código de barras o desde plantilla del rubro | Alta manual de un producto en ≤ 20 s (nombre + precio) |
| RF-04 | Venta rápida (grilla de favoritos, búsqueda, escáner) | 1 producto favorito + efectivo exacto en ≤ 3 toques |
| RF-05 | Venta guiada paso a paso | Cada paso con una sola decisión; siempre se puede volver atrás |
| RF-06 | Cobro con varios métodos y pagos mixtos | Cálculo de vuelto exacto al céntimo; pago mixto efectivo + Yape |
| RF-07 | Venta al fiado y cobro posterior | Saldo del cliente correcto tras cualquier secuencia de ventas, abonos y anulaciones |
| RF-08 | Compras y recepción de mercadería | Al recibir, el stock y el costo promedio se actualizan en la misma operación |
| RF-09 | Inventario con kardex, ajustes con motivo y alertas de stock bajo | Todo cambio de stock tiene un movimiento trazable con autor, dispositivo y motivo |
| RF-10 | Operación sin conexión de todas las funciones del MVP salvo emisión SUNAT | 100 % de ventas, cobros, compras, gastos y ajustes funcionan en modo avión |
| RF-11 | Sincronización multi-dispositivo sin duplicados | 0 duplicados en la batería de pruebas de caos ([TEST_PLAN](../TEST_PLAN.md)) |
| RF-12 | Anulación auditable de ventas y cobros | La anulación exige motivo; la de un vendedor exige PIN del dueño o administrador |
| RF-13 | Caja: apertura, cierre y arqueo | Diferencia esperado/contado calculada a partir de movimientos registrados |
| RF-14 | Dashboard personalizable por rubro | Mostrar, ocultar y ordenar widgets; la configuración se sincroniza |
| RF-15 | Reportes de ventas, margen bruto estimado, gastos y flujo de caja | Totales iguales a la suma de operaciones subyacentes (prueba de conciliación) |
| RF-16 | Emisión de boletas, facturas y notas electrónicas | Ningún comprobante se muestra como "aceptado" sin evidencia válida |
| RF-17 | Entrega del comprobante por WhatsApp o correo | Compartir PDF o enlace en ≤ 2 toques desde la venta |
| RF-18 | Roles y permisos (dueño, administrador, vendedor, contador) | Matriz de permisos verificada por pruebas automáticas por endpoint |
| RF-19 | Planes SaaS con límites | Al superar un límite, el sistema avisa y nunca bloquea una venta en curso |
| RF-20 | Asistente IA opcional (fases posteriores) | Toda extracción requiere confirmación humana antes de guardarse |

## 7. Requisitos no funcionales

| ID | Categoría | Requisito | Medición |
|---|---|---|---|
| RNF-01 | Rendimiento | Registrar una venta localmente | p95 ≤ 300 ms en dispositivo de referencia |
| RNF-02 | Rendimiento | Arranque en frío | ≤ 3 s en dispositivo de referencia (Android 10+, 2 GB RAM; modelo concreto por definir) |
| RNF-03 | Rendimiento | Búsqueda de producto en catálogo de 5 000 ítems | p95 ≤ 150 ms |
| RNF-04 | Recursos | Tamaño del APK por arquitectura | ≤ 30 MB |
| RNF-05 | Recursos | Datos móviles de sincronización | ≤ 2 MB/día para un negocio con 200 ventas diarias |
| RNF-06 | Disponibilidad | API | 99,5 % mensual (la app sigue operando sin ella) |
| RNF-07 | Durabilidad | Ventas confirmadas por el servidor | RPO ≤ 5 min, RTO ≤ 4 h; restauraciones probadas cada mes |
| RNF-08 | Offline | Uso continuo sin conexión | Ventas sin límite de tiempo; la sesión exige revalidación en línea a los 30 días (configurable) |
| RNF-09 | Seguridad | Aislamiento entre negocios | 0 accesos cruzados en pruebas automáticas (FK compuestas + RLS + autorización) |
| RNF-10 | Seguridad | Datos en el dispositivo | Base local cifrada (SQLCipher) con clave en Android Keystore |
| RNF-11 | Accesibilidad | Textos y controles | Escala de fuente al 200 % sin cortes; objetivos táctiles ≥ 48 dp; contraste WCAG 2.2 AA; compatible con TalkBack |
| RNF-12 | Idioma | Español claro del Perú | Sin jerga contable en pantallas operativas (glosario en [FIRST_SALE_FLOW](../ux/FIRST_SALE_FLOW.md)) |
| RNF-13 | Observabilidad | Errores de la app y de la API | 100 % de errores no controlados reportados con contexto sin datos personales |
| RNF-14 | Calidad | Cobertura de pruebas en dominio financiero (ventas, cobros, inventario, sincronización) | ≥ 90 % de líneas en backend; 100 % de reglas de dinero con pruebas de propiedades |
| RNF-15 | Cumplimiento | Datos personales | Conforme a la Ley N.° 29733 y su reglamento vigente ([THREAT_MODEL](../security/THREAT_MODEL.md) §7) |

## 8. Conceptos financieros (definiciones obligatorias)

La interfaz usa palabras simples, pero los cálculos siguen estas definiciones y **no se mezclan**:

| Concepto | Definición en el sistema | Palabra en pantalla |
|---|---|---|
| **Ventas** | Suma de `total` de ventas completadas (no anuladas) en el periodo, con impuestos | "Vendiste" |
| **Ingresos cobrados** | Suma de cobros confirmados menos devoluciones en el periodo, sin importar la fecha de la venta | "Te pagaron" |
| **Cuentas por cobrar** | Ventas al fiado menos cobros aplicados, por cliente | "Te deben" |
| **Costo de lo vendido** | Σ cantidad × costo unitario registrado al momento de la venta | "Te costó" |
| **Utilidad bruta estimada** | Ventas sin impuestos − costo de lo vendido. Es "estimada" porque depende de costos ingresados | "Ganancia de la mercadería" |
| **Utilidad neta estimada** | Utilidad bruta − gastos registrados del periodo | "Lo que te queda" |
| **Flujo de caja** | Entradas de dinero (cobros) − salidas (pagos de compras, gastos, devoluciones), por método | "Movimiento de plata" |

Una **venta registrada no es un comprobante tributario**. Ver [INTEGRATION_PLAN](../sunat/INTEGRATION_PLAN.md).

## 9. Experiencia de usuario

Detalle completo en [FIRST_SALE_FLOW.md](../ux/FIRST_SALE_FLOW.md). Principios:

1. Una decisión por pantalla en los flujos guiados.
2. Ícono + palabra en todos los botones principales; nunca solo ícono.
3. Sin campos obligatorios que no sean imprescindibles (un producto solo exige nombre y precio).
4. Deshacer antes que confirmar: las acciones reversibles no piden confirmación; las irreversibles
   (anular, emitir comprobante) sí, y explican la consecuencia.
5. El estado de sincronización siempre es visible pero nunca bloquea.
6. Cada número del dashboard se puede tocar para ver de dónde sale.

## 10. Modelo de negocio (propuesta, pendiente de decisión)

Freemium con planes por capacidad. **Los precios no están definidos** y requieren validación comercial.

| Plan | Para quién | Límites indicativos |
|---|---|---|
| Gratis | Bodega pequeña que empieza | 1 dispositivo, 1 local, catálogo limitado, sin comprobantes electrónicos |
| Emprendedor | Negocio con ayudante | 3 dispositivos, comprobantes electrónicos con cupo mensual, reportes completos |
| Negocio | Varios locales | Dispositivos y locales adicionales, más cupo de comprobantes, IA incluida con cupo |

La facturación electrónica tiene un costo por comprobante para MiNegocio (proveedor PSE/OSE); el
precio debe cubrirlo ([INTEGRATION_PLAN](../sunat/INTEGRATION_PLAN.md) §6).

## 11. Supuestos

- S1. La mayoría de usuarios objetivo usa Android 8.0 o superior. **Validar** con encuesta piloto.
- S2. Los comerciantes del Nuevo RUS no están obligados a emitir comprobantes electrónicos, pero
  pueden hacerlo voluntariamente ([INTEGRATION_PLAN](../sunat/INTEGRATION_PLAN.md) §2).
- S3. El registro de Yape/Plin es manual (número de operación) porque no hay una API pública
  general de conciliación para comercios pequeños. **Pendiente de validación**.
- S4. Un negocio típico del segmento tiene menos de 5 000 productos y menos de 1 000 ventas diarias.

## 12. Riesgos de producto

| ID | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| RP-1 | El comerciante abandona en la carga inicial de productos | Alta | Alto | Plantillas por rubro, venta "producto libre" sin catálogo, alta desde la propia venta |
| RP-2 | Desconfianza en los números ("la app me robó") | Media | Alto | Trazabilidad tocando cada número; kardex visible; arqueo de caja |
| RP-3 | Cambios normativos SUNAT frecuentes | Alta | Alto | `BillingProvider` + reglas tributarias como datos versionados + revisión mensual de normas |
| RP-4 | Costo por comprobante y por IA superior al precio que se puede cobrar | Media | Alto | Cupos por plan, métricas de costo unitario desde el piloto |
| RP-5 | Fraude interno (anulaciones para quedarse con efectivo) | Media | Medio | Anulación con PIN, auditoría, reporte de anulaciones por usuario |
| RP-6 | Gama baja: lentitud o falta de memoria | Media | Alto | Presupuesto de rendimiento en CI, pruebas en dispositivo físico de referencia |

## 13. Preguntas abiertas

Consolidadas en [PHASE0_REPORT.md](../PHASE0_REPORT.md) §5.
