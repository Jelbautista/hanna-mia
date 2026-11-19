# Modelo de amenazas — MiNegocio AI

Versión 0.1 · Fase 0 · Metodología STRIDE sobre el diagrama de contenedores
([C4](../architecture/C4.md)). Se revisa al cierre de cada fase y **obligatoriamente antes de
producción** (§8).

## 1. Activos

| Activo | Sensibilidad | Por qué importa |
|---|---|---|
| A1 Registros financieros (ventas, cobros, compras, gastos, kardex) | Alta (integridad) | Base de las decisiones y obligaciones tributarias del comerciante |
| A2 Comprobantes y evidencia tributaria | Alta (integridad y no repudio) | Validez legal |
| A3 Datos personales de usuarios (celular, nombre) | Media-alta | Ley N.° 29733 |
| A4 Datos personales de clientes finales (DNI/RUC, nombre, celular, deudas) | Alta | Las deudas (fiado) son información delicada en contextos de barrio |
| A5 Credenciales: tokens, PIN, credenciales del proveedor de facturación, claves de API | Crítica | Suplantación y emisión fraudulenta |
| A6 Datos comerciales agregados (ventas y márgenes del negocio) | Media | Confidencialidad competitiva y riesgo de extorsión |
| A7 Disponibilidad del registro de ventas | Alta | Si no se puede vender, el producto no sirve |

## 2. Fronteras de confianza

```
[Celular: app + SQLite cifrado]  ══TB1══  [Internet]  ══TB2══  [API]  ══TB3══  [PostgreSQL / objetos]
                                                                  ║
                                                                 TB4
                                                                  ║
                                         [PSE/OSE, SMS, IA, pasarela de pago (terceros)]
[Panel admin / soporte] ══TB5══ [API admin]
```

## 3. Actores de amenaza

T-A1 atacante externo oportunista · T-A2 empleado del comercio malintencionado (vendedor que anula
para quedarse con efectivo) · T-A3 persona que obtiene un celular perdido o robado · T-A4 otro
negocio o usuario de la plataforma que intenta ver datos ajenos · T-A5 personal interno con acceso
privilegiado · T-A6 proveedor tercero comprometido · T-A7 contenido malicioso en imágenes o voz
enviadas a la IA (inyección de instrucciones).

## 4. Amenazas y controles (STRIDE)

| ID | STRIDE | Amenaza | Activo | Controles | Verificación |
|---|---|---|---|---|---|
| TH-01 | S | Suplantación por robo de código OTP (SIM swap, ingeniería social) | A5 | OTP de 6 dígitos con vencimiento de 5 min e intentos limitados; aviso al dueño de "nuevo celular conectado" con opción de revocar; PIN para acciones sensibles; transferir la propiedad exige verificación reforzada | Pruebas de límites; prueba de notificación |
| TH-02 | S | Robo de *refresh token* | A5 | Rotación con detección de reutilización (revoca la familia); token ligado a `device_id`; almacenamiento en Keystore | Prueba de reutilización |
| TH-03 | S/E | Acceso entre negocios por manipulación de ids (IDOR) | A1, A4 | `business_id` tomado del token, nunca del cliente; autorización por recurso; FK compuestas; RLS `FORCE` | **T01, T02, T36–T40** ✔ + pruebas de autorización por endpoint (Fase 1) |
| TH-04 | T | Alteración de ventas pasadas para ocultar dinero | A1 | Ventas, líneas y cobros inmutables; anulación con motivo y PIN; auditoría append-only; reporte de anulaciones por usuario | **T11–T20, T35** ✔ |
| TH-05 | T | Modificación de la base local en un celular *rooteado* | A1 | SQLCipher; el servidor revalida cada operación (totales, permisos, PIN); detección de *root* como señal de riesgo (no bloqueo); integridad de la app con Play Integrity (evaluar) | Pruebas de operaciones adulteradas rechazadas |
| TH-06 | T/R | Repetición o reordenamiento malicioso de operaciones de sincronización | A1 | `op_id` único, `payload_hash`, `device_seq`, TLS | **T21–T24** ✔ + batería de caos |
| TH-07 | R | "Yo no anulé esa venta" | A1 | Auditoría con actor, dispositivo, autorizante, motivo y hora del servidor; evidencia inmutable | T35 ✔ |
| TH-08 | I | Celular perdido con datos del negocio | A3, A4, A6 | SQLCipher con clave en Keystore; PIN o biometría para abrir; revocación remota que borra los datos locales al recibir la orden; cierre de sesión por inactividad configurable | Prueba de revocación |
| TH-09 | I | Fuga de datos personales en logs, errores o analítica | A3, A4 | Logs estructurados con lista blanca de campos; enmascaramiento de celular y documento; analítica sin datos personales; revisión en CI (búsqueda de patrones de DNI y celular en logs de prueba) | Prueba de logs |
| TH-10 | I | Soporte accede a datos del negocio sin necesidad | A1, A4, A6 | *Grants* con consentimiento, alcance y vencimiento; doble factor; visibilidad para el dueño; mínimo privilegio | Pruebas de autorización del módulo O |
| TH-11 | I | Enlace del PDF del comprobante adivinable | A2, A4 | Token aleatorio de 128 bits con vencimiento; sin ids secuenciales | Prueba |
| TH-12 | D | Bombeo de SMS (*SMS pumping*) que dispara costos | Costo | Límites por número, prefijo, IP y dispositivo; CAPTCHA adaptativo tras anomalías; alertas de gasto; lista de prefijos permitidos (Perú por defecto) | Pruebas de límite + alerta |
| TH-13 | D | API caída o saturada | A7 | Offline-first (la venta no depende de la API); límites de tasa; autoescalado; backoff con *jitter* en la app | Pruebas de carga (Fase 5) |
| TH-14 | E | Vendedor que se otorga permisos de dueño | A1 | Roles solo modificables por el dueño; verificación en el servidor; auditoría de cambios de rol | Pruebas de autorización |
| TH-15 | S/T | Emisión fraudulenta de comprobantes con credenciales robadas del proveedor | A2, A5 | Credenciales en el gestor de secretos; por negocio cuando el proveedor lo permita; rotación; alertas por volumen anómalo de emisión | Revisión antes de producción |
| TH-16 | T | Envío accidental de documentos reales desde pruebas | A2 | Cuatro barreras ([INTEGRATION_PLAN](../sunat/INTEGRATION_PLAN.md) §7) | **T27** ✔ |
| TH-17 | T/I | Inyección de instrucciones en imágenes o voz enviadas a la IA | A1 | La salida de la IA es una propuesta tipada (esquema estricto); confirmación humana; la IA no tiene herramientas de escritura; el texto extraído se trata como dato | Pruebas de inyección (Fase 6) |
| TH-18 | I | Proveedor de IA que retiene o entrena con datos | A4, A6 | Proveedor con política contractual compatible; minimización (sin datos de clientes); opción de desactivar la IA | Revisión contractual (Fase 6) |
| TH-19 | T | Dependencias comprometidas (cadena de suministro) | Todos | Lockfiles con hashes; Dependabot o Renovate; escaneo (pip-audit, osv-scanner); imágenes base mínimas y firmadas; SBOM | CI |
| TH-20 | I/T | Inyección SQL o en parámetros | A1 | SQLAlchemy con parámetros ligados; Pydantic en todas las entradas; sin SQL dinámico con datos de usuario | SAST (Bandit, Semgrep) en CI |
| TH-21 | D/T | Pérdida de datos del servidor (fallo, ransomware) | A1, A2 | Copias diarias + PITR; copias en otra cuenta o región con inmutabilidad; restauración mensual verificada; evidencia WORM | Simulacro de restauración |
| TH-22 | S | *Webhooks* falsos de la pasarela de suscripción | Ingresos | Verificación de firma, idempotencia y consulta de confirmación a la pasarela | Prueba |

## 5. Riesgos residuales aceptados (a revisar)

- **R-1**: un celular *rooteado* puede leer su propia base local mientras la app está desbloqueada.
  Aceptado: solo afecta datos que ese usuario ya podía ver.
- **R-2**: un vendedor puede registrar una venta por un monto menor al real y quedarse con la
  diferencia. Es un fraude fuera del sistema; se mitiga con el arqueo de caja y el reporte de ventas
  por vendedor, pero no se elimina.
- **R-3**: el OTP por SMS es vulnerable a SIM swap. Mitigado con avisos y PIN; se evaluará una
  passkey como segundo factor opcional.

## 6. Requisitos de seguridad derivados (lista de control)

1. Toda tabla de negocio con `business_id`, FK compuestas y RLS (verificado por prueba que recorre
   el catálogo de tablas).
2. Ningún endpoint sin permiso declarado (prueba que recorre el router).
3. Secretos solo en el gestor de secretos; `.env` solo para desarrollo con valores *fake*;
   escaneo de secretos en CI (gitleaks o equivalente).
4. TLS 1.2+ y HSTS; *certificate pinning* en la app: **evaluar** frente al riesgo de dejar sin
   servicio a apps viejas cuando rote el certificado.
5. Cifrado en reposo: disco de BD y objetos (proveedor), SQLCipher en el celular y cifrado de sobre
   (KMS) para credenciales de terceros.
6. Validación de entradas con Pydantic estricto; tamaños máximos de cuerpo y de lote.
7. Límites de tasa por usuario, dispositivo, IP y endpoint sensible.
8. Cabeceras de seguridad en el panel web (CSP, `frame-ancestors`, etc.).
9. Política de retención y anonimización ([DATABASE_DESIGN](../architecture/DATABASE_DESIGN.md) §8).
10. Registro de auditoría para: autenticación, cambios de rol, anulaciones, cambios de precio,
    ajustes de inventario, emisión y notas de crédito, accesos de soporte y exportaciones.

## 7. Protección de datos personales (Perú)

Marco: **Ley N.° 29733**, Ley de Protección de Datos Personales, y su **nuevo Reglamento aprobado
por D.S. N.° 016-2024-JUS** (publicado el 30/11/2024), que derogó el D.S. 003-2013-JUS y entró en
vigor a los 120 días calendario de su publicación (fines de marzo de 2025; las fuentes difieren
entre el 29, 30 y 31 de marzo). Algunas obligaciones, como la designación del Oficial de Protección
de Datos, tienen plazos de implementación propios. Fuentes: [MINJUS en gob.pe](https://www.gob.pe/institucion/minjus/noticias/1067368-ejecutivo-aprueba-nuevo-reglamento-de-la-ley-de-proteccion-de-datos-personales),
[texto en congreso.gob.pe](https://www.congreso.gob.pe/Docs/DGP/DIDP/files/ds_016-2024-jus.pdf),
[El Peruano](https://www.elperuano.pe/noticia/266995-minjusdh-el-lunes-31-regira-nuevo-reglamento-de-ley).

> No es asesoría legal. Las siguientes medidas deben validarse con un abogado especializado
> **antes de producción** (pregunta bloqueante Q7).

| Tema | Diseño propuesto | Estado |
|---|---|---|
| Roles | MiNegocio es **titular** de los datos de sus usuarios (comerciantes) y **encargado** de los datos de los clientes finales que cada comerciante registra | ⚠ Validar |
| Consentimiento | Aceptación explícita de la política de privacidad al registrarse; consentimiento separado y opcional para analítica, IA y comunicaciones comerciales (el reglamento exige consentimiento expreso para llamadas publicitarias) | ⚠ Validar texto |
| Bancos de datos | Evaluar la obligación de inscribir los bancos de datos personales ante la autoridad (ANPD) | ✖ Pendiente |
| Flujo transfronterizo | Si la nube está fuera del Perú, evaluar las obligaciones de transferencia internacional; criterio para elegir región (Q5) | ✖ Pendiente |
| Medidas de seguridad | Controles de §6, documento de seguridad y gestión de incidentes con notificación según la normativa | ⚠ |
| Derechos ARCO | Acceso, rectificación, cancelación y oposición desde la app (descarga de mis datos, eliminación de cuenta con anonimización) y canal de atención | ⚠ Diseño en Fase 5 |
| Minimización | Cliente final: solo nombre y celular por defecto; el documento solo si se emite un comprobante | ✔ Diseño |
| Retención | Equilibrio entre supresión y obligación tributaria ([DATABASE_DESIGN](../architecture/DATABASE_DESIGN.md) §8) | ⚠ Plazos por validar |
| Oficial de Protección de Datos | Evaluar la obligación según el tamaño y el tipo de tratamiento | ✖ Pendiente |
| Encargados terceros | Contratos con proveedores (nube, SMS, PSE, IA, pasarela) con cláusulas de protección de datos | ⚠ |

## 8. Puerta de seguridad previa a producción

No se habilita producción sin:

- [ ] Revisión de este modelo de amenazas con el código real (Fase 5).
- [ ] Prueba de penetración externa de la API y la app (alcance: TH-01 a TH-22).
- [ ] Pruebas automáticas de aislamiento y autorización al 100 % de los endpoints.
- [ ] Restauración de copias verificada.
- [ ] Revisión legal de la privacidad (§7) y publicación de la política.
- [ ] Plan de respuesta a incidentes con contactos y plantillas de notificación.
- [ ] Inventario de secretos y procedimiento de rotación probado.
