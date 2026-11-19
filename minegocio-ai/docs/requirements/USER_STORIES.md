# Historias de usuario — MiNegocio AI

Versión 0.1 · Fase 0. Formato: **Como** rol **quiero** acción **para** beneficio. Criterios de
aceptación (CA) verificables; las historias críticas usan Gherkin. Prioridad MoSCoW y fase en
[BACKLOG.md](BACKLOG.md).

Personas: Rosa (dueña de bodega), Lucía (vendedora), Carlos (ferretero con RUC), contador, soporte.

---

## A. Identidad

**US-A-01** Como Rosa quiero registrarme con mi número de celular para no tener que recordar una contraseña.
- CA1: recibo un código de 6 dígitos por SMS o WhatsApp y al ingresarlo quedo dentro en ≤ 60 s con 3G.
- CA2: con un código incorrecto 5 veces debo pedir uno nuevo; el mensaje explica qué hacer.
- CA3: no se pide correo ni contraseña.

**US-A-02** Como Rosa quiero entrar en un celular nuevo para seguir con mi negocio si cambio de equipo.
- CA1: tras verificar el código, el celular descarga mi negocio y queda registrado como dispositivo nuevo.
- CA2: el celular anterior sigue activo hasta que yo lo desconecte.

**US-A-03** Como Rosa quiero invitar a mi hija como vendedora para que atienda en su celular sin ver mis ganancias.
- CA1: comparto una invitación por WhatsApp; al aceptarla Lucía entra con rol Vendedor.
- CA2: Lucía no ve costos, márgenes ni reportes completos (prueba de permisos por pantalla y por endpoint).

**US-A-04** Como Rosa quiero un PIN de 4 dígitos para abrir la app rápido y autorizar anulaciones.
- CA1: el PIN funciona sin conexión.
- CA2: tras 5 intentos fallidos la espera aumenta (30 s, 1 min, 5 min…).

**US-A-05** Como Rosa quiero desconectar un celular perdido para que nadie use mi negocio desde ahí.
```gherkin
Escenario: Revocar un dispositivo perdido
  Dado que el celular de Lucía está registrado en mi negocio
  Cuando lo desconecto desde "Mis celulares"
  Entonces sus tokens dejan de funcionar en ≤ 1 minuto
  Y las operaciones que envíe con fecha posterior a la revocación se rechazan
  Y las operaciones con fecha anterior se aceptan y quedan marcadas para revisión
```

## B. Negocio

**US-B-01** Como Rosa quiero crear mi negocio con solo el nombre para empezar a vender ya.
- CA1: funciona sin conexión; se sincroniza después.
- CA2: se crea automáticamente un local "Principal".

**US-B-02** Como Carlos quiero registrar mi RUC y mi régimen para que la app me ofrezca los comprobantes que me corresponden.
- CA1: un RUC con dígito verificador inválido se rechaza con un mensaje claro.
- CA2: en el Nuevo RUS no se ofrece factura; el texto de orientación cita su fuente o dice "consulta con tu contador".

**US-B-03** Como Carlos quiero agregar un segundo local para separar el stock de cada tienda. *(Fase 5)*
- CA1: cada local tiene su propio stock; las ventas registran el local.

**US-B-04** Como Rosa quiero decidir si se permite vender sin stock para no frenar ventas cuando no actualicé la mercadería.
- CA1: por defecto se permite y se muestra una alerta; si se desactiva, la app pide confirmación al vender sin stock (sin bloquear al dueño).

## C. Onboarding

**US-C-01** Como Rosa quiero elegir "Bodega" y recibir productos sugeridos para no escribir todo desde cero.
- CA1: veo ~60 productos genéricos; marco los míos y les pongo precio en una sola pantalla.
- CA2: los productos sugeridos no traen precio inventado.

**US-C-02** Como Rosa quiero saltar cualquier pregunta para vender aunque no tenga tiempo.
- CA1: cada pantalla tiene "Lo hago después"; la app me lo recuerda una sola vez al día siguiente.

**US-C-03** Como Lucía quiero hacer una venta de práctica para aprender sin miedo a equivocarme.
- CA1: la venta de práctica no aparece en reportes, stock ni sincronización.

## D. Productos

**US-D-01** Como Rosa quiero agregar un producto con solo nombre y precio para cargarlo en segundos.
- CA1: alta en ≤ 20 s; costo, stock y categoría son opcionales.

**US-D-02** Como Carlos quiero escanear el código de barras para agregar y encontrar productos sin escribir.
- CA1: un código existente abre el producto en ≤ 1 s; uno nuevo pide nombre y precio.
- CA2: un código ya usado en otro producto muestra cuál es.

**US-D-03** Como Carlos quiero variantes (medida, color) para vender "Tubo PVC ½" y "¾" como un solo producto.
- CA1: cada variante tiene su precio, stock y código de barras.

**US-D-04** Como Rosa quiero elegir mis productos favoritos para tenerlos a un toque al vender.
- CA1: hasta 24 favoritos ordenables por arrastre; se sincronizan entre mis celulares.

**US-D-05** Como Rosa quiero cambiar un precio para actualizarlo cuando sube el proveedor.
- CA1: las ventas anteriores conservan el precio de entonces.
- CA2: queda registrado quién cambió el precio, cuándo, y el valor anterior.

**US-D-06** Como Rosa quiero importar mis productos desde un Excel para no digitarlos uno por uno. *(Fase 3)*
- CA1: plantilla descargable; vista previa con errores por fila antes de importar.

## E. Compras

**US-E-01** Como Rosa quiero registrar la mercadería que llegó para que mi stock y mis costos estén al día.
```gherkin
Escenario: Recepción de compra con costo total por línea
  Dado que "Arroz 5 kg" tiene stock 3 y costo promedio S/ 18.0000
  Cuando registro una compra de 10 unidades con total de línea S/ 190.00
  Entonces el costo unitario de la compra es S/ 19.0000
  Y el stock queda en 13
  Y el costo promedio queda en S/ 18.7692
  Y el historial del producto muestra el ingreso con mi nombre y la hora
```

**US-E-02** Como Rosa quiero guardar a mis proveedores para registrar compras más rápido.
- CA1: nombre obligatorio; RUC y teléfono opcionales.

**US-E-03** Como Rosa quiero marcar una compra como "por pagar" para saber cuánto debo a proveedores.
- CA1: el reporte "Debo" lista las compras pendientes; al pagar se registra el egreso.

**US-E-04** Como Rosa quiero anular una compra mal registrada para corregir el stock.
- CA1: exige motivo; genera movimientos inversos; la compra queda visible como anulada.

## F. Inventario

**US-F-01** Como Rosa quiero ver cuánto me queda de cada producto para saber qué pedir.
- CA1: lista ordenable por "se acaba primero"; funciona sin conexión.

**US-F-02** Como Rosa quiero que me avise cuando algo se esté acabando para no quedarme sin stock.
- CA1: si el stock baja del mínimo, aparece en el widget "Stock bajo" y en una notificación diaria (configurable).

**US-F-03** Como Rosa quiero corregir la cantidad de un producto diciendo por qué para que cuadre con lo que tengo.
- CA1: motivos: se dañó, se venció, lo regalé, me equivoqué, otro; sin motivo no se guarda.

**US-F-04** Como Rosa quiero contar la mercadería y que la app calcule la diferencia para cuadrar mi inventario.
```gherkin
Escenario: Conteo mientras otro celular vende
  Dado que el stock de "Leche tarro" era 14 a las 10:05
  Y que a las 10:07 el celular de Lucía vendió 2
  Cuando registro a las 10:20 que conté 12 a las 10:05
  Entonces el ajuste calculado es −2
  Y el stock final es 10
  Y el conteo queda marcado "revisar" explicando la venta concurrente
```

**US-F-05** Como Rosa quiero ver el historial de un producto para entender por qué cambió su cantidad.
- CA1: cada movimiento muestra tipo, cantidad, quién, celular, hora y motivo o venta asociada.

## G. Ventas

**US-G-01** Como Lucía quiero vender tocando el producto y "Cobrar" para atender rápido cuando hay cola.
```gherkin
Escenario: Venta rápida de un favorito con efectivo exacto
  Dado que "Gaseosa 500 ml" (S/ 2.50) está en mis favoritos
  Y que no hay conexión a internet
  Cuando toco "Gaseosa 500 ml", luego "Cobrar S/ 2.50", luego "Efectivo exacto"
  Entonces la venta D002-000046 queda registrada en ≤ 300 ms
  Y se registró un cobro en efectivo de S/ 2.50
  Y el stock local de "Gaseosa 500 ml" disminuyó en 1
  Y la venta aparece como pendiente de sincronizar
```

**US-G-02** Como Rosa quiero una venta paso a paso para no equivocarme cuando estoy aprendiendo.
- CA1: una decisión por pantalla; botón "Atrás" en todos los pasos; resumen legible antes de cobrar.

**US-G-03** Como Rosa quiero vender "por monto" algo que no está en mi lista para no perder la venta.
- CA1: botón "+ S/" con monto y descripción opcional; queda como "Producto libre".

**US-G-04** Como Rosa quiero anular una venta equivocada para que mis números sean correctos.
```gherkin
Escenario: Vendedora anula con autorización de la dueña
  Dado que Lucía registró la venta D002-000045 por S/ 12.00 en efectivo
  Cuando Lucía elige "Anular" con motivo "me equivoqué de producto"
  Entonces la app pide el PIN de Rosa
  Y al ingresarlo la venta queda anulada, el cobro anulado y el stock restituido
  Y la app indica "Devuelve S/ 12.00"
  Y la auditoría registra a Lucía como autora y a Rosa como autorizante
```
- CA extra: si la venta tiene boleta aceptada, la app guía a emitir nota de crédito en lugar de anular.

**US-G-05** Como Carlos quiero aplicar un descuento a una línea para negociar con clientes frecuentes.
- CA1: el descuento no supera el importe de la línea; los totales e impuestos se recalculan exactos.

**US-G-06** Como Rosa quiero enviar la nota de venta por WhatsApp para que el cliente tenga su detalle.
- CA1: la nota dice claramente "Nota de venta – no es comprobante de pago".

## H. Cobros

**US-H-01** Como Lucía quiero que la app me diga el vuelto para no equivocarme.
- CA1: botones S/ 10, 20, 50, 100 y otro; vuelto exacto en letra grande.

**US-H-02** Como Rosa quiero registrar pagos con Yape o Plin con el número de operación para verificarlos después.
- CA1: el número de operación es opcional pero se sugiere; el reporte separa por método.

**US-H-03** Como Carlos quiero recibir una parte en efectivo y otra con tarjeta para aceptar pagos mixtos.
- CA1: la suma de pagos debe igualar el total o dejar saldo como fiado (con cliente).

**US-H-04** Como Rosa quiero marcar los Yape como verificados para saber que el dinero llegó.
- CA1: lista de Yape/Plin sin verificar del día; marcar uno registra quién y cuándo.

**US-H-05** Como Rosa quiero registrar una devolución de dinero para que la caja cuadre.
- CA1: la devolución reduce "Te pagaron" y la caja esperada (si fue en efectivo).

## I. Clientes y fiado

**US-I-01** Como Rosa quiero vender al fiado a un vecino para no perder la venta y no olvidar la deuda.
- CA1: el fiado exige cliente (nombre y celular bastan); el saldo se actualiza al instante.

**US-I-02** Como Rosa quiero registrar un abono parcial para saber cuánto le falta pagar.
```gherkin
Escenario: Abonos sobre fiado
  Dado que Don Pedro debe S/ 45.00 por dos ventas
  Cuando registro un abono de S/ 20.00 en Yape
  Entonces su saldo es S/ 25.00
  Y "Te deben" disminuye en S/ 20.00
  Y "Te pagaron" de hoy aumenta en S/ 20.00 aunque las ventas fueron de otros días
```

**US-I-03** Como Rosa quiero enviar el estado de cuenta por WhatsApp para cobrar sin discusiones.
- CA1: muestra cada venta y abono con fecha y el saldo final.

**US-I-04** Como Rosa quiero un recordatorio de los clientes que me deben hace más de 15 días. *(Fase 3)*
- CA1: la app prepara el mensaje; yo decido si lo envío (nunca envío automático).

## J. Facturación electrónica

**US-J-01** Como Carlos quiero configurar mis comprobantes electrónicos paso a paso para emitir sin ayuda técnica.
- CA1: el asistente valida RUC y régimen, explica cada paso y termina con una boleta de prueba en el ambiente de pruebas.
- CA2: no se pide la Clave SOL si el proveedor elegido no la requiere; si se requiere, se explica por qué y cómo se protege.

**US-J-02** Como Carlos quiero emitir una boleta al terminar la venta para entregarla al cliente.
```gherkin
Escenario: Boleta aceptada
  Dado que mi negocio tiene facturación configurada
  Y que completé una venta de S/ 25.00 con conexión
  Cuando toco "Emitir boleta"
  Entonces veo "Enviando…" con la serie y el número asignados
  Y cuando el proveedor entrega evidencia de aceptación veo "Aceptada por SUNAT"
  Y puedo compartir el PDF por WhatsApp

Escenario: Sin evidencia no hay aceptación
  Dado que el proveedor no respondió (timeout)
  Cuando consulto la boleta
  Entonces veo "Estamos confirmando con SUNAT" y nunca "Aceptada"
```

**US-J-03** Como Carlos quiero emitir factura a una empresa con su RUC para que pueda usar el crédito fiscal.
- CA1: sin RUC válido no se permite factura; con RUC, nombre y dirección se autocompletan si la fuente está disponible.

**US-J-04** Como Carlos quiero ver el estado de cada comprobante para saber si debo corregir algo.
- CA1: los rechazados muestran el motivo en lenguaje simple y la acción sugerida.

**US-J-05** Como Carlos quiero emitir una nota de crédito para corregir una boleta o factura aceptada.
- CA1: exige motivo (catálogo); referencia al comprobante original; si es total, la venta queda anulada por compensación.

**US-J-06** Como Carlos quiero compartir el comprobante en PDF por WhatsApp o correo en 2 toques.
- CA1: el PDF incluye los datos exigidos por la representación impresa (por validar con el proveedor).

**US-J-07** Como contador quiero descargar los comprobantes del mes para hacer la declaración.
- CA1: descarga de XML, PDF y evidencia, más un CSV resumen por periodo.

## K. Caja, gastos y reportes

**US-K-01** Como Lucía quiero abrir caja con el sencillo inicial para saber cuánto debe haber al final.

**US-K-02** Como Rosa quiero cerrar caja contando billetes y monedas para saber si falta o sobra plata.
- CA1: calculadora por denominación; muestra esperado, contado y diferencia, con el detalle del cálculo.

**US-K-03** Como Rosa quiero anotar un gasto (luz, bolsas, pasaje) para saber lo que realmente me queda.
- CA1: categorías simples con ícono; foto opcional del recibo.

**US-K-04** Como Rosa quiero ver el resumen del día para saber cómo me fue.
- CA1: "Vendiste", "Te pagaron", "Te deben", "Gastaste", "Te queda", con definiciones según el PRD §8.

**US-K-05** Como Carlos quiero ver la ganancia por producto para decidir qué vender más.
- CA1: margen "estimado" con aviso de productos sin costo.

**US-K-06** Como Rosa quiero enviar a mi contador las ventas, compras y gastos del mes.
- CA1: exportación Excel/CSV con un formato estable documentado.

## L. Dashboard

**US-L-01** Como Rosa quiero ver al abrir la app lo más importante de mi negocio.
- CA1: los widgets por defecto dependen del rubro; cargan sin conexión en ≤ 500 ms.

**US-L-02** Como Carlos quiero mostrar, ocultar y ordenar los indicadores para ver lo que me sirve.
- CA1: cambio por arrastre; se guarda y se sincroniza a mis otros celulares.

**US-L-03** Como Rosa quiero tocar un número y ver de dónde sale para confiar en él.
- CA1: "Ventas de hoy S/ 845.50" → lista de las ventas que lo suman.

## M. Sincronización

**US-M-01** Como Rosa quiero vender aunque no haya internet para no perder ventas.
- CA1: todas las funciones del MVP salvo emitir comprobantes funcionan en modo avión.

**US-M-02** Como Rosa quiero saber si todo está guardado en la nube para estar tranquila.
- CA1: indicador permanente (✔, ↻ N, ⚠); aviso si hay operaciones de más de 24 h sin sincronizar.

**US-M-03** Como Rosa quiero que mi celular y el de mi hija muestren lo mismo para no tener cuentas distintas.
- CA1: tras sincronizar ambos, ventas del día, stock y saldos coinciden (prueba de convergencia).

**US-M-04** Como Rosa quiero ver y resolver lo que "requiere atención" para no perder nada.
- CA1: cada ítem explica qué pasó y ofrece una acción (reintentar, corregir, descartar con motivo).

## N. Suscripción

**US-N-01** Como Rosa quiero ver mi plan y cuánto he usado para no llevarme sorpresas.

**US-N-02** Como Carlos quiero mejorar mi plan desde la app para emitir más comprobantes.

**US-N-03** Como Rosa quiero que, si llego al límite o me atraso en el pago, igual pueda vender y ver mis datos.
- CA1: ninguna venta se bloquea por plan (prueba automática); la exportación siempre está disponible.

## O. Soporte y administración

**US-O-01** Como agente de soporte quiero ver la salud técnica de un negocio sin ver sus ventas para ayudar respetando su privacidad.
- CA1: sin *grant* del dueño solo veo metadatos técnicos; con *grant* veo lo autorizado por el tiempo indicado, y el dueño ve el registro.

**US-O-02** Como administrador de plataforma quiero métricas de activación, sincronización y facturación para detectar problemas.

**US-O-03** Como administrador quiero actualizar plantillas de rubro y catálogos tributarios sin publicar otra versión de la app.

## P. Asistente IA *(Fase 6)*

**US-P-01** Como Rosa quiero tomar foto a un producto para que la app proponga el nombre.
- CA1: la propuesta se puede editar; el precio lo pongo yo.

**US-P-02** Como Rosa quiero tomar foto a la factura del proveedor para registrar la compra sin digitar.
- CA1: veo la lista extraída con campos dudosos resaltados; nada se guarda hasta que confirmo.

**US-P-03** Como Lucía quiero decir "dos gaseosas y un pan" para armar la venta con la voz.
- CA1: el carrito se llena como propuesta; el cobro sigue siendo manual.

**US-P-04** Como Rosa quiero preguntar "¿cuánto gané esta semana?" y recibir una respuesta con las cifras.
- CA1: la respuesta cita los números de los reportes y enlaza al detalle; si no hay datos de costo, lo dice.

**US-P-05** Como Rosa quiero recomendaciones de qué reponer según lo que vendo.
- CA1: lista de sugerencias con la razón ("vendes 12 por semana y te quedan 3"); no crea compras sola.
