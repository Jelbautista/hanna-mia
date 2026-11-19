# Onboarding y flujo de primera venta — MiNegocio AI

Versión 0.1 · Fase 0 · Meta: **primera venta en ≤ 5 minutos** desde la instalación (mediana)

## 1. Principios de diseño para baja alfabetización digital

1. **Una pregunta por pantalla**, con opciones grandes de ícono + palabra. No se usan listas
   desplegables en el onboarding.
2. **Todo se puede omitir**: "Lo hago después" está siempre visible. Omitir nunca bloquea la venta.
3. **Lenguaje del mostrador**, no del contador (glosario §6).
4. **Mostrar, no explicar**: el resultado aparece en la pantalla siguiente ("Así se verá tu venta").
5. **Errores que enseñan**: decir qué pasó y qué hacer ("Falta el precio. Escríbelo aquí ↓").
6. **Accesibilidad**: textos que crecen hasta 200 %, objetivos táctiles ≥ 48 dp (64 dp en la grilla
   de venta), contraste AA, etiquetas para TalkBack, sin depender solo del color (✔ ⚠ con texto).
7. **Voz opcional desde el inicio** (Fase 6): ícono de micrófono en búsqueda; nunca obligatorio.

## 2. Mapa del primer uso

```
[Bienvenida] → [Celular + código] → P1 Rubro → P2 Productos → P3 Qué controlar
     → P4 Comprobantes → P5 Primera venta → [Venta rápida] → [¡Lo lograste!] → [Inicio/Dashboard]
```

Duración objetivo por tramo (prueba de usabilidad, §7): registro ≤ 60 s · P1–P4 ≤ 90 s ·
carga de productos ≤ 2 min · venta ≤ 30 s.

## 3. Pantallas

### 3.0 Bienvenida

```
┌──────────────────────────────┐
│        [ilustración]         │
│  Dime qué vendes y te ayudo  │
│       a organizarlo          │
│                              │
│  Ventas, mercadería y plata  │
│  claras, aunque no tengas    │
│  internet.                   │
│                              │
│  [ Empezar  → ]              │
│  Ya tengo cuenta             │
└──────────────────────────────┘
```

Registro: número de celular → código por SMS o WhatsApp (autocompletado cuando el sistema lo
permita) → nombre ("¿Cómo te llamas?"). Sin contraseña. Se pide crear un **PIN de 4 dígitos**
después de la primera venta, no antes.

### 3.1 P1 — ¿Qué tipo de negocio tienes?

```
┌──────────────────────────────┐
│ ¿Qué vendes?           1 de 5│
│ ┌────────┐ ┌────────┐        │
│ │ 🏪     │ │ 🔩     │        │
│ │ Bodega │ │Ferrete-│        │
│ └────────┘ │ ría    │        │
│ ┌────────┐ └────────┘        │
│ │ 🍞     │ ┌────────┐        │
│ │Panade- │ │ 🍲     │        │
│ │ ría    │ │ Menú / │        │
│ └────────┘ │ comida │        │
│ ┌────────┐ └────────┘        │
│ │ 👕     │ ┌────────┐        │
│ │ Ropa / │ │ ✨     │        │
│ │ bazar  │ │ Otro   │        │
│ └────────┘ └────────┘        │
│              Lo hago después │
└──────────────────────────────┘
```

Cada rubro activa una **plantilla** (datos versionados en el servidor y embebidos en la app):

| Rubro | Productos sugeridos | Unidades frecuentes | Widgets por defecto | Particularidades |
|---|---|---|---|---|
| Bodega | ~60 genéricos ("Gaseosa 500 ml", "Arroz 1 kg", "Pan francés") | unidad, kg | Ventas de hoy, Te deben, Stock bajo, Más vendidos | Fiado activado; venta por monto ("S/ 1 de pan") |
| Ferretería | ~40 genéricos por familia | unidad, metro, kg, caja | Ventas de hoy, Stock bajo, Compras recientes | Código de barras y variantes (medida); factura frecuente |
| Panadería | ~25 | unidad, kg | Ventas de hoy, Más vendidos, Gastos | Producción diaria (fase posterior); poco stock |
| Menú / comida | ~15 platos y bebidas | unidad | Ventas de hoy, Operaciones, Gastos | Sin stock por defecto; **tasa de IGV especial por validar** |
| Ropa / bazar | ~20 | unidad | Ventas de hoy, Margen, Stock bajo | Variantes talla/color |
| Otro | Ninguno | unidad | Ventas de hoy, Operaciones, Te pagaron | — |

> Los nombres sugeridos son genéricos (sin marcas) y el comerciante los edita.

### 3.2 P2 — ¿Cómo quieres registrar tus productos?

```
┌──────────────────────────────┐
│ Tus productos          2 de 5│
│                              │
│ [✓ Elegir de una lista   ]   │  ← recomendado según rubro
│ [▦ Escanear códigos      ]   │
│ [✎ Escribirlos yo        ]   │
│ [⏭ Vender sin lista      ]   │  ← "producto libre": precio y listo
│                              │
│ 📷 Foto o 🎤 voz: muy pronto │  ← fase 6, deshabilitado y rotulado
└──────────────────────────────┘
```

- **Elegir de una lista**: grilla de sugeridos con casillas → pantalla de precios en lote (un campo
  numérico por fila, teclado numérico, "S/" fijo). Lo que no tenga precio queda sin marcar.
- **Escanear**: cámara continua; si el código no existe, se pide nombre y precio. Se evaluará una
  base de nombres por código de barras (fuente y licencia por definir).
- **Escribir**: nombre + precio. Lo demás (costo, stock, categoría) es opcional y se pide después
  ("¿Quieres que te avise cuando se acabe?").
- **Vender sin lista**: se puede vender "Producto libre" (descripción opcional + monto). Al cerrar el
  día se sugiere: "Vendiste 14 productos libres. ¿Quieres guardarlos en tu lista?".

### 3.3 P3 — ¿Qué quieres controlar?

Casillas preseleccionadas según el rubro, que también configuran el dashboard:

```
[✓] Cuánto vendo cada día
[✓] Quién me debe (fiado)
[✓] Qué se está acabando
[ ] Cuánto gano por producto     → pedirá costos
[ ] Mis gastos
[ ] La caja (abrir y cerrar)
```

### 3.4 P4 — ¿Quieres configurar tus comprobantes electrónicos?

```
┌──────────────────────────────┐
│ Boletas y facturas     4 de 5│
│                              │
│ ¿Tienes RUC?                 │
│ [ Sí ]  [ No ]  [ No sé ]    │
│                              │
│ (Si Sí) ¿En qué régimen?     │
│ [Nuevo RUS] [RER] [MYPE]     │
│ [General]   [No sé]          │
│                              │
│ Esto lo puedes hacer después.│
│ Tus ventas se registran igual│
└──────────────────────────────┘
```

- La respuesta solo **orienta** (por ejemplo: "En el Nuevo RUS no estás obligado a emitir
  electrónicamente, pero puedes hacerlo"; texto revisado según el
  [plan SUNAT](../sunat/INTEGRATION_PLAN.md) §2). La configuración real se hace después, en
  "Comprobantes", en un flujo propio con validación del RUC.
- Nunca se afirma una obligación tributaria que no esté verificada. Ante la duda se muestra:
  "Consulta con tu contador o en SUNAT".

### 3.5 P5 — ¿Hacemos tu primera venta?

```
┌──────────────────────────────┐
│ ¡Todo listo!           5 de 5│
│                              │
│ Hagamos una venta de prueba  │
│ o una de verdad.             │
│                              │
│ [ Vender ahora → ]           │
│ [ Venta de práctica ]        │  ← no afecta reportes ni stock
│ Ir al inicio                 │
└──────────────────────────────┘
```

La **venta de práctica** se guarda en un modo sandbox local que se borra al terminar. Nunca se
sincroniza ni genera comprobantes.

## 4. Venta rápida (modo por defecto)

```
┌──────────────────────────────┐
│ 🔍 Buscar   ▦ Escanear   ↻ 3 │ ← indicador de sincronización
│ ┌─────┐┌─────┐┌─────┐┌─────┐ │
│ │Gaseo││Pan  ││Leche││Arroz│ │  grilla de favoritos (64 dp)
│ │2.50 ││0.20 ││4.20 ││4.50 │ │  toque = +1 · mantener = cantidad
│ └─────┘└─────┘└─────┘└─────┘ │
│ ┌─────┐┌─────┐┌─────┐┌─────┐ │
│ │Huevo││Aceit││Azúca││ + S/│ │  "+ S/" = producto libre por monto
│ └─────┘└─────┘└─────┘└─────┘ │
│──────────────────────────────│
│ 2 × Gaseosa 500 ml    5.00 ✕ │
│ 1 × Leche tarro       4.20 ✕ │
│──────────────────────────────│
│ [  COBRAR  S/ 9.20        ]  │
└──────────────────────────────┘
```

**Cobro** (una pantalla):

```
Total S/ 9.20
[💵 Efectivo exacto]  [💵 Me pagó con… ]  [📱 Yape]  [📱 Plin]
[💳 Tarjeta]          [📒 Fiado]          [➗ Dividir pago]
"Me pagó con…": botones S/ 10 · S/ 20 · S/ 50 · S/ 100 · otro → "Vuelto: S/ 0.80" en grande
```

- **Conteo de toques** para 1 favorito en efectivo exacto: (1) producto, (2) Cobrar,
  (3) Efectivo exacto → venta registrada ✔. Cumple la meta O2 (≤ 3).
- Yape/Plin: campo opcional "N.° de operación" (para conciliar después).
- Fiado: exige cliente (búsqueda o "Nuevo: nombre y celular").
- Tras cobrar: tarjeta ✔ con "Compartir nota" · "Emitir boleta" (si está configurado) · "Nueva venta".
- **Deshacer** durante 5 s ("Venta registrada · Deshacer"). Después, solo con anulación auditada.

## 5. Venta guiada (principiantes o por preferencia)

Pasos con una sola decisión cada uno y barra de progreso:

1. **¿Qué vendiste?** Búsqueda grande + favoritos + escáner + "Otro producto".
2. **¿Cuántos?** Botones − / + y teclado; para kg, "¿Por peso o por monto?".
3. **¿Algo más?** [Agregar otro producto] [No, eso es todo].
4. **Revisa**: lista legible ("2 gaseosas de S/ 2.50 = S/ 5.00").
5. **¿Cómo te pagó?** Igual que en venta rápida.
6. **¿Le das comprobante?** [No] [Nota de venta (WhatsApp)] [Boleta] [Factura]; las dos últimas
   solo si están configuradas.
7. **¡Listo!** Resumen + "Vender otra vez".

El modo se cambia en Ajustes o con el interruptor "Ayúdame paso a paso" en la pantalla de venta.

## 6. Glosario de interfaz

| Término técnico | En pantalla |
|---|---|
| Venta / ingreso devengado | "Vendiste" |
| Ingreso cobrado | "Te pagaron" |
| Cuentas por cobrar | "Te deben" / "Fiado" |
| Costo de ventas | "Te costó" |
| Utilidad bruta | "Ganancia de la mercadería" |
| Utilidad neta | "Lo que te queda" |
| Flujo de caja | "Movimiento de plata" |
| Kardex | "Historial del producto" |
| Ajuste de inventario | "Corregir cantidad" (motivos: se dañó, se venció, lo regalé, me equivoqué, otro) |
| Arqueo | "Contar la caja" |
| Comprobante electrónico | "Boleta" / "Factura" (con el estado: "Enviando…", "Aceptada por SUNAT", "Rechazada: …") |
| Nota de venta | "Nota (no es boleta)" |
| Sincronizar | "Guardar en la nube" · "Todo guardado ✔" |

## 7. Medición del flujo

Eventos de producto (sin datos personales; con consentimiento de analítica):
`onboarding_started`, `otp_verified`, `business_type_selected{type}`, `products_method{method}`,
`products_added{count}`, `tax_question_answered{has_ruc,regime}`, `first_sale_completed{mode,
seconds_since_install, taps}`, `onboarding_skipped{step}`.

**Prueba de usabilidad Fase 3**: 8 comerciantes por ronda (bodega ×3, ferretería ×2, otros ×3) en
su propio celular. Tareas: registrarse, cargar 5 productos y vender 2 productos con vuelto.
Criterios de éxito: ≥ 7 de 8 completan sin ayuda, mediana ≤ 5 min y SUS ≥ 70.
