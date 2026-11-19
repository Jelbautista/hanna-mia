# Los 26 reels de Horno Mía

Un reel por cada fórmula de gancho de `/ig-reel` (las 26 de `hooks.json`), con guion, texto en pantalla, plano sugerido y caption.
Escritos en la voz de `voice.md`. Todo dato sale de la web: 72 horas de reposo, 12 horas colgado, 900 g, preventa S/ 35 y regular S/ 45, 50 % de adelanto por WhatsApp, entrega en Ate y Lima Este.
Nada se publica solo: tú grabas y tú publicas.

## Cómo leerlo

- **Dice:** una línea por plano. Cada línea cambia de plano; ninguna pasa de unos 4 segundos.
- **Texto en pantalla:** seis palabras o menos, dentro de la zona segura (nada por encima de y=230 ni por debajo de y=1440 en 1080x1920, y libres los 230 px de la derecha). La tarjeta del gancho está en el primer fotograma.
- **Tiempos:** estimación a 165 palabras por minuto. Mídete leyendo en voz alta y ajusta.
- **Cierre:** cada reel pide una sola cosa (reservar con la palabra PANETON, guardar, enviar o comentar).
- **Captions:** primera línea concreta, una sola petición, alérgenos y 3 hashtags (el tope actual es 5).

## Reels que necesitan un dato tuyo (marcados con ⚠)

Estas fórmulas piden algo que solo tú sabes (un costo, años de oficio, números reales, un cliente) o una grabación concreta (los dos clips del reel 13, el experimento del reel 17). Lo que falta está entre `{{llaves}}`. **No inventes el dato**: si no lo tienes, salta ese reel. Son los reels 1, 4, 6, 8, 12, 13, 15, 16, 17, 23, 24 y 25.
Los otros 14 se pueden grabar hoy mismo con lo que ya dice la web.

## Antes de grabar, confirma

1. La palabra clave **PANETON**: es propuesta mía, no estaba definida.
2. Que la preventa de **S/ 35** siga vigente el día que publiques.
3. Que el panetón de **café** (reel 24) esté a la venta y a qué precio.
4. Fórmulas adaptadas para no mentir: el reel 5 (Time Collapse) invierte la plantilla, porque el panetón no "solía tardar" menos; el reel 9 enseña una tarjeta en vez de contar "cuánto me tomó"; el reel 20 y otros usan cuidados que ya están en la web.

## Sobre las puntuaciones

`beats.py` y `hookscore.py` están hechos para inglés: no leen bien las tildes ni "setenta y dos" como cifra, así que no uso su puntaje de gancho como veredicto. Sí usé `beats.py` para los tiempos y para que cada gancho quede por debajo de 3 segundos. El humanizador no encontró em dashes ni caracteres invisibles; solo marca que las frases son parejas de largo, que es normal en un guion hablado.

---

## Reel 1 · Cost Confession

**Fórmula:** {Specific amount} is what {one mistake} cost me.  
**Duración estimada:** ~17 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Pon tu error real y su costo. Si no hay uno, salta este reel.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | {{Monto}} soles me costó {{un error real}}. | {{MONTO}} SOLES PERDIDOS | Tú frente al horno, mano en la frente |
| 0:02.5 | Y lo peor es que {{por qué se pudo evitar}}. | {{LO EVITABLE}} | Corte a la bandeja del error |
| 0:06.2 | Desde entonces hay una regla: {{la regla}}. | REGLA NUEVA | Nota pegada junto al horno |
| 0:08.7 | Cada tanda sale con esa regla. | CADA TANDA | Masa entrando al horno |
| 0:10.9 | Por eso cada panetón sale de una tanda pequeña. | TANDAS PEQUEÑAS | Panetón recién salido |
| 0:14.2 | Reserva el tuyo: escribe PANETON. | ESCRIBE PANETON | Panetón sobre la mesa |
| 0:16.0 | {{Monto}} soles. | {{MONTO}} SOLES | Cierre sobre el horno |

**Caption (para pegar):**

```
{{Monto}} soles me costó {{un error real}}. Hoy cada tanda sale con una regla nueva.

Panetón hecho a mano, en tandas pequeñas. Panetón de Navidad hecho a mano en Lima Este.

Reserva el tuyo: escribe PANETON.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 2 · Negative Command

**Fórmula:** Stop {common action}. Do {alternative} instead.  
**Duración estimada:** ~17 s a 165 palabras por minuto · **Cierre:** CTA guardar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Deja de guardar tu panetón en la nevera. | NEVERA: NO | Mano cierra la puerta de la nevera |
| 0:02.9 | Déjalo sobre la mesa, en su envoltorio. | EN LA MESA, ENVUELTO | Panetón sobre la mesa |
| 0:05.5 | Lejos del calor. | LEJOS DEL CALOR | Panetón junto a una ventana sin sol |
| 0:06.5 | El frío le saca la humedad a la miga. | EL FRÍO RESECA LA MIGA | Corte lento de una porción |
| 0:09.8 | Sin abrir, aguanta semanas. | SIN ABRIR: SEMANAS | Panetón cerrado |
| 0:11.3 | Ya abierto, bolsa hermética. Dos o tres días. | ABIERTO: 2 A 3 DÍAS | Mano cierra la bolsa |
| 0:14.2 | Guarda este video para diciembre. | GUÁRDALO | Panetón en la mesa de Navidad |
| 0:16.0 | Nevera, no. | NEVERA: NO | Mano cierra la puerta de la nevera |

**Caption (para pegar):**

```
No guardes tu panetón en la nevera: el frío reseca la miga.

Sin abrir, sobre la mesa y lejos del calor. Abierto, en su envoltorio o en bolsa hermética, 2 o 3 días. Panetón de Navidad hecho a mano en Lima Este.

Guarda este video para diciembre.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 3 · Nobody Tells You

**Fórmula:** Nobody tells you that {uncomfortable truth about the thing they want}.  
**Duración estimada:** ~20 s a 165 palabras por minuto · **Cierre:** CTA enviar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Tu panetón se reseca. Te digo por qué. | ¿POR QUÉ SE RESECA? | Panetón cortado en la mesa |
| 0:02.9 | Casi nunca es por el tiempo. | NO ES EL TIEMPO | Calendario pasando días |
| 0:05.1 | Es por cómo lo guardas. | ES CÓMO LO GUARDAS | Panetón en la nevera |
| 0:06.9 | Sin abrir, se conserva semanas. | SIN ABRIR: SEMANAS | Panetón cerrado |
| 0:08.7 | Ya abierto, envoltorio o bolsa hermética. | ENVOLTORIO O BOLSA | Mano envolviendo una porción |
| 0:10.9 | Dos o tres días y está en su punto. | 2 A 3 DÍAS | Porción servida |
| 0:14.2 | Mándaselo a quien lo guarda en la nevera. | MÁNDASELO | Pantalla del chat con el video |
| 0:17.1 | Se estropea por sed, no por prisa. | SED, NO PRISA | Panetón sobre la mesa |

**Caption (para pegar):**

```
Un panetón no se estropea por prisa, se estropea por sed.

Sin abrir, se conserva semanas. Ya abierto, 2 o 3 días. Panetón de Navidad hecho a mano en Lima Este.

Mándaselo a quien lo guarda en la nevera.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 4 · The Replacement

**Fórmula:** {This thing} replaced {expensive thing} for {price}.  
**Duración estimada:** ~20 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Pon el producto y precio reales que reemplaza. No lo exageres.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Este de 35 soles reemplaza al de {{precio}}. | S/ 35 vs {{PRECIO}} | Dos panetones lado a lado |
| 0:02.9 | No es más grande: pesa 900 gramos. | 900 G | Panetón sobre una balanza |
| 0:05.5 | Lleva harina de cañihua tostada y reposo largo. | CAÑIHUA + REPOSO LARGO | Harina de cañihua tostada |
| 0:08.4 | Los frutos van deshidratados y partidos, no confitados. | FRUTA PARTIDA | Cuchillo partiendo fruta |
| 0:11.3 | Tres días de reposo, a mano, en tanda pequeña. | 3 DÍAS, A MANO | Manos doblando la masa |
| 0:14.6 | Es la preventa: después sube a 45. | PREVENTA S/ 35 | Etiqueta de precio |
| 0:17.1 | Escribe PANETON y te paso cómo reservar. | ESCRIBE PANETON | Panetón en la mesa |
| 0:19.6 | Treinta y cinco soles. | S/ 35 | Cierre sobre la etiqueta |

**Caption (para pegar):**

```
Panetón de 900 g: S/ 35 en preventa, S/ 45 después.

Harina de cañihua, huevos frescos y fruta partida, no confitada. Tres días de reposo. Panetón de Navidad hecho a mano en Lima Este.

Escribe PANETON y te paso cómo reservar.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 5 · Time Collapse

**Fórmula:** This used to take me {long time}. It now takes {short time}.  
**Duración estimada:** ~16 s a 165 palabras por minuto · **Cierre:** CTA enviar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Industrial: horas. El nuestro: tres días. | HORAS → 72 HORAS | Reloj acelerado y luego quieto |
| 0:02.2 | No hay atajo. | SIN ATAJO | Masa reposando |
| 0:03.3 | La masa se refresca cada día, durante semanas. | CADA DÍA, SEMANAS | Mano alimentando la masa |
| 0:06.2 | Dos amasados, con horas de reposo en medio. | 2 AMASADOS | Manos amasando |
| 0:09.1 | Después, el horno. | DESPUÉS, EL HORNO | Puerta del horno |
| 0:10.2 | Si lo apuras, la miga lo cuenta. | LA MIGA LO CUENTA | Corte de panetón |
| 0:12.7 | Mándaselo a quien sigue comprando por la caja. | MÁNDASELO | Pantalla del chat |
| 0:15.6 | Tres días. | 72 HORAS | Reloj quieto |

**Caption (para pegar):**

```
Un panetón industrial sale en horas. El nuestro tarda tres días.

La masa se refresca cada día, con dos amasados y horas de reposo. Sin atajos. Panetón de Navidad hecho a mano en Lima Este.

Mándaselo a quien compra panetón de caja.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 6 · The Receipt

**Fórmula:** I {did thing} for {N days}. Here are the actual numbers.  
**Duración estimada:** ~11 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Necesitas tus números reales y una grabación de pantalla. No muestres datos de clientes.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | {{N}} semanas horneando. Estos son los números reales. | {{N}} SEMANAS. NÚMEROS REALES. | Grabación de pantalla del WhatsApp |
| 0:02.9 | {{N}} reservas. | {{N}} RESERVAS | Pantalla con el conteo |
| 0:03.6 | {{N}} panetones entregados. | {{N}} ENTREGADOS | Cajas listas para entrega |
| 0:04.7 | {{N}} personas que repitieron. | {{N}} REPITIERON | Mensajes de clientes, tapados los nombres |
| 0:06.2 | Lo que no esperaba: {{aprendizaje real}}. | LO INESPERADO | Tú a cámara |
| 0:08.4 | Reserva el tuyo: escribe PANETON. | ESCRIBE PANETON | Panetón en la mesa |
| 0:10.2 | {{N}} semanas. | {{N}} SEMANAS | Cierre sobre el calendario |

**Caption (para pegar):**

```
{{N}} semanas horneando una tanda por semana. Estos son los números reales.

{{N}} reservas y {{N}} panetones entregados. Panetón de Navidad hecho a mano en Lima Este.

Reserva el tuyo: escribe PANETON.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 7 · Wrong Way, Right Way

**Fórmula:** You are doing {thing} wrong, and it is not your fault. {The fix}.  
**Duración estimada:** ~17 s a 165 palabras por minuto · **Cierre:** CTA guardar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Panetón duro. No es tu culpa. | QUEDÓ DURO. NO ES TU CULPA. | Mano apretando una porción dura |
| 0:02.2 | El frío le saca la humedad a la miga. | EL FRÍO RESECA | Panetón saliendo de la nevera |
| 0:05.5 | Pasa cuando se guarda en la nevera. | NEVERA = MIGA SECA | Puerta de la nevera |
| 0:08.0 | Calienta solo la porción, unos segundos. | SOLO LA PORCIÓN | Porción entrando al microondas |
| 0:10.2 | Sírvela tibia. | SÍRVELA TIBIA | Porción servida en plato |
| 0:10.9 | Y la próxima vez, déjalo en la mesa. | LA PRÓXIMA, EN LA MESA | Panetón sobre la mesa |
| 0:13.8 | Guarda este video para cuando sobre. | GUÁRDALO | Panetón a medio comer |
| 0:16.0 | Duro, no. | DURO, NO | Porción tibia |

**Caption (para pegar):**

```
¿Panetón duro? Calienta solo la porción unos segundos y sírvela tibia.

El frío de la nevera le saca la humedad a la miga. Mejor sobre la mesa, en su envoltorio. Panetón de Navidad hecho a mano en Lima Este.

Guarda este video para cuando sobre.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 8 · Insider Leak

**Fórmula:** I spent {N years} {inside the thing}. Here is what we never said out loud.  
**Duración estimada:** ~19 s a 165 palabras por minuto · **Cierre:** CTA enviar

> ⚠ Pon los años reales que llevas horneando. Si no los quieres decir, salta este reel.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Esto no sale en la caja del panetón. | {{N}} AÑOS HORNEANDO | Tú con el delantal, primer plano |
| 0:02.9 | La caja no te dice cuántas horas reposó la masa. | ¿CUÁNTAS HORAS? | Caja de panetón cerrada |
| 0:06.5 | Un panetón industrial sale en horas. | HORAS | Reloj acelerado |
| 0:08.7 | El nuestro tarda tres días. | 3 DÍAS | Calendario con tres días marcados |
| 0:10.6 | Esa diferencia se nota al partirlo. | SE NOTA AL PARTIRLO | Corte limpio de panetón |
| 0:12.7 | Pregunta siempre cuántas horas reposó. | PREGUNTA: ¿CUÁNTAS HORAS? | Tú señalas a cámara |
| 0:14.6 | Mándaselo a quien compra panetón cada año. | MÁNDASELO | Pantalla del chat |
| 0:17.1 | Esto no sale en la caja. | NO SALE EN LA CAJA | Cierre sobre el horno |

**Caption (para pegar):**

```
Lo que no sale en la caja del panetón: cuántas horas reposó la masa.

Llevo {{N}} años horneando. El industrial sale en horas, el nuestro en tres días. Panetón de Navidad hecho a mano en Lima Este.

Mándaselo a quien compra panetón cada año.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 9 · The Steal

**Fórmula:** Steal this {artifact}. It took me {time} to get right.  
**Duración estimada:** ~16 s a 165 palabras por minuto · **Cierre:** CTA guardar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Roba esta tarjeta: panetón en tres pasos. | ROBA ESTA TARJETA | Tarjeta en pantalla completa |
| 0:02.5 | Uno: sin abrir, en la mesa, lejos del calor. | 1 · SIN ABRIR: MESA | Resalta el paso uno |
| 0:05.8 | Dos: abierto, en su envoltorio o bolsa hermética. | 2 · ABIERTO: ENVOLTORIO | Resalta el paso dos |
| 0:08.7 | Tres: nunca en la nevera. | 3 · NUNCA NEVERA | Resalta el paso tres |
| 0:10.6 | Sin abrir dura semanas. Abierto, dos o tres días. | SEMANAS / 2 A 3 DÍAS | Tarjeta completa otra vez |
| 0:13.8 | Haz captura de pantalla. | HAZ CAPTURA | Dedos tomando captura |
| 0:15.3 | Tres pasos. | 3 PASOS | Tarjeta |

**Caption (para pegar):**

```
Cuida tu panetón en tres pasos: mesa, envoltorio y nunca nevera.

Sin abrir dura semanas; abierto, 2 o 3 días. Panetón de Navidad hecho a mano en Lima Este.

Haz captura de pantalla.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 10 · If This, Then Watch

**Fórmula:** If you {specific situation}, this {short time} fixes it.  
**Duración estimada:** ~19 s a 165 palabras por minuto · **Cierre:** CTA reservar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Panetón en Lima Este: así se reserva. | ¿PANETÓN EN LIMA ESTE? | Mapa o letrero de Ate |
| 0:02.5 | Primero: 35 soles en preventa, 45 después. | 1 · S/ 35 PREVENTA | Etiqueta de precio |
| 0:05.1 | Segundo: reservas con 50 % de adelanto por WhatsApp. | 2 · 50 % POR WHATSAPP | Pantalla del WhatsApp |
| 0:08.4 | Tercero: confirmamos tu fecha cuando cierra la tanda. | 3 · FECHA AL CERRAR TANDA | Calendario |
| 0:11.3 | Entregamos en Ate y Lima Este. | ENTREGA: ATE Y LIMA ESTE | Caja saliendo en moto o auto |
| 0:13.4 | Gratis desde dos unidades, en zonas definidas. | GRATIS DESDE 2 | Dos cajas apiladas |
| 0:16.0 | Escribe PANETON y te paso el enlace. | ESCRIBE PANETON | Teléfono en la mano |
| 0:18.6 | Lima Este. | LIMA ESTE | Cierre |

**Caption (para pegar):**

```
Panetón en Ate y Lima Este: reserva con 50 % de adelanto por WhatsApp.

Preventa S/ 35, luego S/ 45. Confirmamos tu fecha cuando cierra la tanda. Entrega gratis desde 2 unidades en zonas definidas. Panetón de Navidad hecho a mano en Lima Este.

Escribe PANETON y te paso el enlace.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 11 · Numbered With A Favourite

**Fórmula:** {N} {things} that {outcome}. Number {k} is the one nobody uses.  
**Duración estimada:** ~21 s a 165 palabras por minuto · **Cierre:** CTA enviar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Tres ingredientes. El tres es mi favorito. | 3 INGREDIENTES · EL 3 GANA | Tres ingredientes en fila |
| 0:02.5 | Uno: harina de cañihua. Sabor tostado, sigue siendo panetón. | 1 · CAÑIHUA | Harina tostada |
| 0:05.8 | Dos: huevos frescos. La yema entera deja la miga dorada. | 2 · HUEVOS FRESCOS | Yemas |
| 0:09.4 | Tres: arándanos y frutos secos, deshidratados y partidos. | 3 · FRUTA PARTIDA | Cuchillo partiendo fruta |
| 0:12.4 | No confitados. Se doblan a mano dentro de la masa. | A MANO, DENTRO | Manos doblando la masa |
| 0:16.0 | Por eso cada corte tiene algo. | CADA CORTE TIENE ALGO | Corte de panetón |
| 0:18.2 | Mándaselo a quien prefiere la fruta confitada. | MÁNDASELO | Pantalla del chat |
| 0:20.7 | El tres. | EL 3 | Fruta partida |

**Caption (para pegar):**

```
Tres ingredientes que se notan al partirlo: cañihua, huevos frescos y fruta partida.

La fruta va deshidratada y partida, no confitada, y se dobla a mano dentro de la masa. Panetón de Navidad hecho a mano en Lima Este.

Mándaselo a quien prefiere la fruta confitada.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 12 · The Objection

**Fórmula:** "{Objection they actually say}." Fine. Here is the version that works anyway.  
**Duración estimada:** ~17 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Cambia la objeción por la frase exacta que te escribieron, con sus errores.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | "Es caro." Bien. Mira lo que pagas. | "ES CARO." BIEN. | Tú a cámara con el panetón |
| 0:02.5 | Tres días de reposo. | 3 DÍAS DE REPOSO | Masa reposando |
| 0:04.0 | Harina de cañihua tostada y huevos frescos. | CAÑIHUA + HUEVOS | Ingredientes en la mesa |
| 0:06.5 | Fruta deshidratada y partida, no confitada. | FRUTA PARTIDA | Cuchillo partiendo fruta |
| 0:08.7 | Hecho a mano, en tandas pequeñas. | A MANO, TANDA PEQUEÑA | Manos con la masa |
| 0:10.9 | En preventa son 35. Tú decides si lo vale. | PREVENTA S/ 35 | Etiqueta de precio |
| 0:14.2 | Escribe PANETON si quieres reservarlo. | ESCRIBE PANETON | Teléfono en la mano |
| 0:16.0 | Es caro. | ¿CARO? | Cierre sobre el panetón |

**Caption (para pegar):**

```
Esto hay detrás de un panetón de S/ 45: tres días de reposo.

Cañihua tostada, huevos frescos y fruta partida, hecho a mano en tandas pequeñas. En preventa, S/ 35. Panetón de Navidad hecho a mano en Lima Este.

Escribe PANETON si quieres reservarlo.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 13 · Before And After, On Screen

**Fórmula:** {Show the old thing}. {Show the new thing}. {One sentence on the lever}.  
**Duración estimada:** ~18 s a 165 palabras por minuto · **Cierre:** CTA enviar

> Necesitas dos clips: la masa el día uno y la masa a las 72 horas.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Esta es la masa el día uno. | DÍA 1 | Masa recién amasada, plano fijo |
| 0:02.5 | Esta es la misma masa a las 72 horas. | 72 HORAS | Mismo plano, masa crecida |
| 0:05.8 | A las 72 horas suelta el borde del bol y respira. | SUELTA EL BORDE Y RESPIRA | Primer plano del borde del bol |
| 0:09.8 | Cambió una sola cosa: el tiempo. | SOLO EL TIEMPO | Corte entre los dos planos |
| 0:12.0 | Ese es el momento que esperamos. | EL MOMENTO | Mano tocando la masa |
| 0:14.2 | Mándaselo a quien no cree en esperar. | MÁNDASELO | Pantalla del chat |
| 0:16.7 | Día uno. Día tres. | DÍA 1 → DÍA 3 | Los dos planos juntos |

**Caption (para pegar):**

```
Día 1 y día 3: la misma masa. Cambió una sola cosa, el tiempo.

A las 72 horas suelta el borde del bol y respira. Panetón de Navidad hecho a mano en Lima Este.

Mándaselo a quien no cree en esperar.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 14 · The Callout

**Fórmula:** {Specific group}, this is the one you have been ignoring.  
**Duración estimada:** ~17 s a 165 palabras por minuto · **Cierre:** CTA escribir

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Empresas de Lima Este: el regalo que ignoran. | EMPRESAS DE LIMA ESTE | Caja de panetón sobre un escritorio |
| 0:02.9 | Desde 20 unidades hay tarifa por volumen. | DESDE 20: TARIFA POR VOLUMEN | Cajas apiladas |
| 0:05.5 | Panetón de 900 gramos. | 900 G | Panetón en su caja |
| 0:06.9 | Tres días de reposo. | 3 DÍAS DE REPOSO | Masa reposando |
| 0:08.4 | Hecho en tandas pequeñas, según lo reservado. | TANDAS PEQUEÑAS | Hornada saliendo |
| 0:10.9 | Entregamos en Ate y Lima Este. | ATE Y LIMA ESTE | Caja entregada en una oficina |
| 0:13.1 | Escríbenos por WhatsApp si compras para tu equipo. | ESCRÍBENOS POR WHATSAPP | Teléfono con el chat |
| 0:16.0 | Empresas de Lima Este. | DESDE 20 | Cajas apiladas |

**Caption (para pegar):**

```
Panetón para empresas de Lima Este: desde 20 unidades, tarifa por volumen.

900 g, tres días de reposo, tandas pequeñas. Entregamos en Ate y Lima Este. Panetón de Navidad hecho a mano en Lima Este.

Escríbenos por WhatsApp si compras para tu equipo.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 15 · The Flop Record

**Fórmula:** My first {N} {attempts} did nothing. Here is what changed on {N+1}.  
**Duración estimada:** ~16 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Solo sirve si es verdad. Pon tus intentos y qué cambió de verdad.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Mis primeras {{N}} tandas no salieron como quería. | {{N}} TANDAS FALLIDAS | Panetón que no salió bien |
| 0:02.9 | En la {{N+1}} cambió una cosa. | LA {{N+1}} | Panetón bueno al lado |
| 0:05.5 | {{El cambio real}}. | {{EL CAMBIO}} | Plano del cambio |
| 0:06.5 | No fue suerte: {{por qué no fue suerte}}. | NO FUE SUERTE | Tú a cámara |
| 0:09.4 | Hoy cada tanda pasa por esos tres días de reposo. | 3 DÍAS DE REPOSO | Masa reposando |
| 0:13.1 | Reserva el tuyo: escribe PANETON. | ESCRIBE PANETON | Panetón en la mesa |
| 0:14.9 | {{N}} tandas. | {{N}} TANDAS | Cierre |

**Caption (para pegar):**

```
Mis primeras {{N}} tandas no salieron como quería. En la {{N+1}} cambió una cosa.

{{El cambio real}}. Hoy cada panetón lleva tres días de reposo. Panetón de Navidad hecho a mano en Lima Este.

Reserva el tuyo: escribe PANETON.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 16 · The Verbatim Question

**Fórmula:** "{Question exactly as it was asked}" - I get this every week.  
**Duración estimada:** ~13 s a 165 palabras por minuto · **Cierre:** CTA guardar

> ⚠ Cambia la pregunta por la frase exacta con la que te la escriben.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | "¿Cuánto dura un panetón?" Cada diciembre. | "¿CUÁNTO DURA?" | Tú a cámara con el panetón |
| 0:02.2 | Sin abrir, semanas. | SIN ABRIR: SEMANAS | Panetón cerrado |
| 0:03.3 | Ya abierto, dos o tres días. | ABIERTO: 2 A 3 DÍAS | Panetón abierto |
| 0:05.5 | En su envoltorio o en bolsa hermética. | ENVOLTORIO O BOLSA | Mano cerrando la bolsa |
| 0:08.0 | Siempre lejos del calor, nunca en la nevera. | LEJOS DEL CALOR. NUNCA NEVERA. | Panetón sobre la mesa |
| 0:10.9 | Guarda este video para diciembre. | GUÁRDALO | Panetón en la mesa de Navidad |
| 0:12.7 | ¿Cuánto dura? | ¿CUÁNTO DURA? | Cierre |

**Caption (para pegar):**

```
¿Cuánto dura un panetón? Sin abrir, semanas; abierto, 2 o 3 días.

Siempre lejos del calor y nunca en la nevera. Panetón de Navidad hecho a mano en Lima Este.

Guarda este video para diciembre.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 17 · Head To Head

**Fórmula:** {A} versus {B}. I ran both for {time} and one of them was not close.  
**Duración estimada:** ~18 s a 165 palabras por minuto · **Cierre:** CTA comentar

> ⚠ Haz el experimento de verdad y filma los cortes. Cambia el gancho si el resultado no es ese.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Nevera contra mesa. Tres días. No estuvo cerca. | NEVERA vs MESA | Dos panetones lado a lado |
| 0:02.9 | Este estuvo tres días en la nevera. | NEVERA: 3 DÍAS | Panetón A |
| 0:05.5 | Este estuvo tres días sobre la mesa. | MESA: 3 DÍAS | Panetón B |
| 0:08.0 | Corté los dos. Mira la miga. | MIRA LA MIGA | Cortes lado a lado |
| 0:10.2 | {{Lo que se ve en la miga de cada uno}}. | {{LO QUE SE VE}} | Primer plano de cada corte |
| 0:13.8 | Gana {{el ganador}}. | GANA {{EL GANADOR}} | Corte ganador |
| 0:14.9 | ¿Tú dónde lo guardas? Cuéntame. | ¿DÓNDE LO GUARDAS? | Tú a cámara |
| 0:16.7 | Nevera contra mesa. | NEVERA vs MESA | Cierre |

**Caption (para pegar):**

```
Nevera contra mesa: dos panetones, tres días y un corte.

{{Lo que se vio en la miga de cada uno}}. Panetón de Navidad hecho a mano en Lima Este.

¿Dónde guardas el tuyo? Cuéntame en los comentarios.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 18 · Cold Open Demo

**Fórmula:** {Start mid-action, already doing the thing.} Watch what this does.  
**Duración estimada:** ~16 s a 165 palabras por minuto · **Cierre:** CTA reservar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Mira dentro de un panetón de tres días. | 3 DÍAS ADENTRO | Cuchillo ya cortando, primer plano |
| 0:02.9 | Miga abierta. | MIGA ABIERTA | Corte lento |
| 0:03.6 | La yema entera deja el color dorado. | YEMA ENTERA = DORADO | Miga cerca de la cámara |
| 0:06.2 | Fruta partida en cada corte. | FRUTA EN CADA CORTE | Cuchillo atravesando |
| 0:08.0 | El sabor tostado viene de la cañihua. | SABOR TOSTADO: CAÑIHUA | Porción servida |
| 0:10.6 | Todo eso son tres días. | 3 DÍAS | Panetón entero |
| 0:12.4 | Escribe PANETON y te cuento cómo reservar. | ESCRIBE PANETON | Teléfono en la mano |
| 0:14.9 | Tres días, por dentro. | 3 DÍAS | Corte |

**Caption (para pegar):**

```
Así se ve por dentro un panetón de tres días: miga abierta y fruta partida en cada corte.

Yema entera para el color dorado y cañihua tostada para el sabor. Panetón de Navidad hecho a mano en Lima Este.

Escribe PANETON y te cuento cómo reservar.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 19 · The Deadline

**Fórmula:** {Thing} changes on {date}. Do {action} before then.  
**Duración estimada:** ~18 s a 165 palabras por minuto · **Cierre:** CTA reservar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Este panetón sube de 35 a 45 soles. | S/ 35 → S/ 45 | Etiqueta que se cambia |
| 0:02.9 | Cuando se acabe el lote de preventa. No hay fecha fija. | LOTE PEQUEÑO | Panetones en la mesa |
| 0:06.9 | Cada tanda se hornea según lo ya reservado. | SEGÚN LO RESERVADO | Cuaderno de reservas |
| 0:09.8 | Nada de stock dormido. | SIN STOCK DORMIDO | Estante vacío |
| 0:11.3 | Reservas con el 50 % de adelanto por WhatsApp. | 50 % POR WHATSAPP | Pantalla del chat |
| 0:14.6 | Escribe PANETON antes de que se acabe. | ESCRIBE PANETON | Teléfono en la mano |
| 0:17.1 | 35 soles. | S/ 35 | Etiqueta de precio |

**Caption (para pegar):**

```
Este panetón sube de S/ 35 a S/ 45 cuando se acabe el lote de preventa.

No hay fecha fija: cada tanda se hornea según lo ya reservado. Panetón de Navidad hecho a mano en Lima Este.

Escribe PANETON antes de que se acabe.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 20 · Permission

**Fórmula:** You do not need {the thing everyone says you need}.  
**Duración estimada:** ~17 s a 165 palabras por minuto · **Cierre:** CTA guardar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | No necesitas terminarte el panetón el mismo día. | NO LO TERMINES HOY | Panetón a medio comer |
| 0:02.9 | Sin abrir, aguanta semanas. | SIN ABRIR: SEMANAS | Panetón cerrado |
| 0:04.4 | Abierto, dos o tres días. | ABIERTO: 2 A 3 DÍAS | Panetón abierto |
| 0:06.2 | Guárdalo en su envoltorio o en bolsa hermética. | ENVOLTORIO O BOLSA | Mano cerrando la bolsa |
| 0:09.1 | Si sobra, calienta la porción unos segundos. | CALIENTA LA PORCIÓN | Porción entrando al microondas |
| 0:11.6 | Y listo. Sin prisa. | SIN PRISA | Porción servida |
| 0:13.1 | Guarda este video para la Nochebuena. | GUÁRDALO | Mesa de Navidad |
| 0:15.3 | El mismo día, no. | SIN PRISA | Cierre |

**Caption (para pegar):**

```
No necesitas terminarte el panetón el mismo día.

Sin abrir aguanta semanas; abierto, 2 o 3 días en bolsa hermética. Si sobra, calienta la porción unos segundos. Panetón de Navidad hecho a mano en Lima Este.

Guarda este video para la Nochebuena.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 21 · Mid-Sentence Start

**Fórmula:** {...and that is when {the turn}.}  
**Duración estimada:** ~18 s a 165 palabras por minuto · **Cierre:** CTA enviar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | ...y recién ahí soltó el borde del bol. | ...Y RECIÉN AHÍ | Masa soltando el borde, ya en movimiento |
| 0:02.9 | Habían pasado setenta y dos horas. | 72 HORAS DESPUÉS | Reloj con el contador |
| 0:04.4 | La masa se refresca cada día, durante semanas. | CADA DÍA, SEMANAS | Mano alimentando la masa |
| 0:07.3 | Dos amasados, con horas de reposo en medio. | 2 AMASADOS | Manos amasando |
| 0:10.2 | Ese momento no se puede apurar. | NO SE APURA | Primer plano de la masa |
| 0:12.4 | Así empieza cada panetón de Horno Mía. | HORNO MÍA | Panetón terminado |
| 0:14.9 | Mándaselo a quien no tiene paciencia. | MÁNDASELO | Pantalla del chat |
| 0:17.1 | ...y recién ahí. | ...Y RECIÉN AHÍ | Cierre sobre la masa |

**Caption (para pegar):**

```
72 horas después, la masa suelta el borde del bol.

Así empieza cada panetón de Horno Mía: cañihua, tiempo y paciencia. Panetón de Navidad hecho a mano en Lima Este.

Mándaselo a quien no tiene paciencia.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 22 · Contrarian Flip

**Fórmula:** {Well-known saying, inverted.}  
**Duración estimada:** ~16 s a 165 palabras por minuto · **Cierre:** CTA enviar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Lo bueno, si largo, dos veces bueno. | LO BUENO, SI LARGO | Panetón girando lento |
| 0:02.5 | Dicen lo contrario: lo bueno, si breve. | DICEN: SI BREVE | Letras tachadas |
| 0:05.1 | En el panetón es al revés. | AL REVÉS | Corte de panetón |
| 0:07.3 | Setenta y dos horas de reposo. | 72 HORAS DE REPOSO | Masa reposando |
| 0:08.7 | Doce horas colgado boca abajo. | 12 HORAS BOCA ABAJO | Panetón colgado |
| 0:10.6 | Nada de eso es breve. | NADA ES BREVE | Tú negando con la cabeza |
| 0:12.4 | Y se nota al partirlo. | SE NOTA AL PARTIRLO | Corte de panetón |
| 0:14.2 | Mándaselo a alguien impaciente. | MÁNDASELO | Pantalla del chat |
| 0:15.6 | Si largo. | SI LARGO | Cierre |

**Caption (para pegar):**

```
Lo bueno, si largo, dos veces bueno: 72 horas de reposo y 12 colgado boca abajo.

Panetón hecho a mano y en tandas pequeñas. Panetón de Navidad hecho a mano en Lima Este.

Mándaselo a alguien impaciente.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 23 · The Statistic

**Fórmula:** {N}% of {group} {surprising fact}.  
**Duración estimada:** ~16 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Solo con tus datos reales de reservas. Si no los tienes, salta este reel.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | {{N}} % de mis clientes volvió a reservar. | {{N}} % VOLVIÓ | Gráfico simple de tu hoja de reservas |
| 0:02.9 | Ese dato sale de mis propias reservas. | DE MIS RESERVAS | Grabación de pantalla de la hoja |
| 0:05.5 | No es una encuesta: es lo que pasó. | LO QUE PASÓ | Tú a cámara |
| 0:08.4 | {{La razón real, según los clientes}}. | {{LA RAZÓN}} | Mensaje de un cliente, sin nombre |
| 0:10.6 | Cada panetón lleva tres días de reposo. | 3 DÍAS DE REPOSO | Masa reposando |
| 0:13.1 | Reserva el tuyo: escribe PANETON. | ESCRIBE PANETON | Panetón en la mesa |
| 0:14.9 | {{N}} por ciento. | {{N}} % | Cierre |

**Caption (para pegar):**

```
{{N}} % de mis clientes volvió a reservar.

Dato de mis propias reservas: {{cómo lo conté}}. Panetón de Navidad hecho a mano en Lima Este.

Reserva el tuyo: escribe PANETON.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 24 · The Reveal

**Fórmula:** This is the new {thing}.  
**Duración estimada:** ~16 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Confirma que el de café está a la venta y a qué precio.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Este es el panetón de café. | EL PANETÓN DE CAFÉ | Panetón de café levantado a cámara |
| 0:02.2 | Misma masa, mismos tres días de reposo. | MISMA MASA, 3 DÍAS | Masa reposando |
| 0:04.7 | Con café en la masa y frutos por todas partes. | CAFÉ + FRUTOS | Corte con fruta visible |
| 0:08.4 | Pesa 900 gramos. | 900 G | Panetón sobre la balanza |
| 0:09.4 | {{Cómo cambia el sabor, con tus palabras}}. | {{EL SABOR}} | Tú probando una porción |
| 0:12.0 | Escribe PANETON y pregunta por el de café. | ESCRIBE PANETON | Teléfono en la mano |
| 0:14.9 | El de café. | EL DE CAFÉ | Cierre |

**Caption (para pegar):**

```
Panetón de café de 900 g, con la misma masa y tres días de reposo.

Café en la masa y frutos por todas partes. Panetón de Navidad hecho a mano en Lima Este.

Escribe PANETON y pregunta por el de café.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 25 · Someone Else's Result

**Fórmula:** There was one {person} who {outcome} in {time}.  
**Duración estimada:** ~11 s a 165 palabras por minuto · **Cierre:** CTA reservar

> ⚠ Necesita una persona real que te haya dado permiso para contar su caso.

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Hubo una {{persona}} que {{resultado}} en {{tiempo}}. | {{PERSONA}}: {{RESULTADO}} | Foto o mensaje con permiso |
| 0:02.5 | {{Qué pidió}}. | {{QUÉ PIDIÓ}} | Caja del pedido |
| 0:03.3 | {{Qué dijo, con sus palabras}}. | "{{SU FRASE}}" | Mensaje con permiso |
| 0:05.1 | Eso salió de una tanda pequeña, hecha a mano. | TANDA PEQUEÑA | Manos con la masa |
| 0:08.4 | Si quieres lo mismo, escribe PANETON. | ESCRIBE PANETON | Teléfono en la mano |
| 0:10.6 | Una {{persona}}. | {{PERSONA}} | Cierre |

**Caption (para pegar):**

```
Una {{persona}} {{resultado}} en {{tiempo}}.

{{Su frase, con su permiso}} Panetón de Navidad hecho a mano en Lima Este.

Si quieres lo mismo, escribe PANETON.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```

## Reel 26 · The Superlative

**Fórmula:** The {fastest / biggest / only} {thing} is {the answer}.  
**Duración estimada:** ~15 s a 165 palabras por minuto · **Cierre:** CTA guardar

| Tiempo | Dice | Texto en pantalla | Plano |
| --- | --- | --- | --- |
| 0:00.0 | Un buen panetón se reconoce al partirlo. | PÁRTELO | Cuchillo cortando de golpe |
| 0:02.5 | Fruta en cada corte. | FRUTA EN CADA CORTE | Corte con fruta |
| 0:04.0 | Miga abierta. | MIGA ABIERTA | Primer plano de la miga |
| 0:04.7 | Color dorado, de yema entera. | DORADO DE YEMA | Miga cerca de la cámara |
| 0:06.5 | Si la fruta es confitada, lo notas al primer bocado. | ¿CONFITADA? SE NOTA | Primer bocado |
| 0:10.2 | Aquí va deshidratada y partida. | DESHIDRATADA Y PARTIDA | Fruta partida a mano |
| 0:12.0 | Guarda este video para elegir bien. | GUÁRDALO | Panetón en la mesa |
| 0:14.2 | Al partirlo. | PÁRTELO | Cierre |

**Caption (para pegar):**

```
Un buen panetón se reconoce al partirlo: fruta en cada corte, miga abierta y color dorado.

Aquí la fruta va deshidratada y partida, no confitada. Panetón de Navidad hecho a mano en Lima Este.

Guarda este video para elegir bien.

Contiene trigo, huevo, leche y frutos secos.

#panetonlima #navidadperu #panetondenavidad
```
