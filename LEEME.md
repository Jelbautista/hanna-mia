# Horno Lento — sitio de panetones con héroe de scroll

Sitio de una sola página para una panadería ficticia que vende panetones de masa madre por encargo.
Todo es HTML, CSS y JavaScript puro: **sin build, sin dependencias, sin npm**.

```
horno-lento/
  index.html      ← todo el copy editable está aquí
  styles.css      ← colores, tipografías y animaciones
  app.js          ← motor del héroe, interacción y formulario
  assets/
    hero-scrub.mp4     ← vídeo del héroe (material de relleno, 7 s)
    hero-poster.jpg    ← fotograma inicial (mientras carga o si no hay vídeo)
    hero-ending.jpg    ← foto del obrador usada en "El oficio"
```

---

## 1. Cómo abrirlo

**Opción A — doble clic en `index.html`.** Funciona en `file://`. El vídeo se carga por la vía
directa y el resto del sitio opera con normalidad.

**Opción B — con un servidor local (recomendada).** El vídeo se precarga completo en memoria antes
de mostrarlo, que es como está diseñado el héroe:

```
cd horno-lento
python -m http.server 8000
# abrir http://127.0.0.1:8000/
```

Las tipografías (Fraunces, Instrument Sans, IBM Plex Mono) vienen de Google Fonts: se necesita
internet la primera vez. Sin conexión el sitio funciona igual con las fuentes del sistema.

---

## 2. Qué se ve al entrar

1. **Héroe de scroll (600 vh).** Cinco frases de marca entran y salen mientras el vídeo avanza
   exactamente al ritmo del scroll: pausas donde te paras, y el fotograma final espera a que
   llegues al final. Debajo, el titular de reserva queda disponible desde el 86 % del recorrido.
2. **El oficio.** Tres columnas: la firma gráfica (un panetone colgado de dos varillas, cuya cuerda
   se dibuja al bajar), el relato del proceso y una foto del obrador.
3. **Tres ingredientes** con iconos y una cifra que sostiene el argumento.
4. **Tu turno.** Un momento interactivo: se mantiene pulsado el botón y la masa sube en la tina en
   1,5 s; al soltar, vuelve a bajar.
5. **Cómo se cuida**, **preguntas frecuentes**, **reserva** (formulario con validación en cliente) y
   pie.

### El héroe se apaga solo

Si no puede mostrar el scroll interactivo, el héroe se convierte automáticamente en una portada
fija con el titular completo, el botón de reserva y el pie de foto del vídeo. No hace falta tocar
nada. Las cinco condiciones que lo provocan:

| Condición | Cómo se detecta |
|---|---|
| Pantalla de 768 px o menos | media query de ancho |
| El usuario pide menos movimiento | `prefers-reduced-motion: reduce` |
| Ahorro de datos o 2G | `navigator.connection` |
| Vídeo que no carga o no se puede buscar | error o más de 13 s sin estar listo |
| JavaScript desactivado | bloque `<noscript>` con el mismo contenido |

---

## 3. Dónde se cambia el copy

Todo el texto está en `index.html`, sin plantillas ni variables:

| Qué | Dónde |
|---|---|
| Frases del héroe | `div.bandas` → cada `div.banda` (kicker + titular) |
| Titulares de sección | `<h2 class="titulo">` |
| Precio, días y cifras | texto plano en `index.html` (p. ej. "89", "72 horas") |
| Nombre y contacto | cabecera y pie |
| Texto legal | `footer` |

Los cambios de color viven en `styles.css`, al principio, en `:root`:

```
--fondo:#14100c   --panel:#1d1712   --acento:#c99a5b   --acento-alto:#e2b878
--texto:#f3e9d9   --tenue:#b3a48e   --linea:rgba(243,233,217,.16)
```

---

## 4. El vídeo y cómo reemplazarlo

El héroe usa `assets/hero-scrub.mp4` (5,00 s, 1280×720, 24 fps, H.264, 2,6 MB, sin audio),
generado el 14 de octubre de 2026 con Seedance 2.0 a través de la API de Higgsfield. Para
sustituirlo basta con dejar un archivo con el mismo nombre. El sitio necesita dos cosas del clip:

- **Duración entre 5 y 10 s.** El scroll recorre 600 vh; un clip más largo se queda corto y uno
  más corto se dispara.
- **Sin audio y formato H.264 (mp4).** El sonido no se usa nunca.

El sitio también lee dos fotogramas, que se usan como poster y como foto del final:

- `assets/hero-poster.jpg` — primer fotograma (se ve mientras carga el vídeo y en móvil).
- `assets/hero-ending.jpg` — último fotograma (ya no se usa en la página; la foto de "El oficio"
  pasó a ser `assets/foto-amasado.jpg`, ver §4).

**Si el vídeo falla**, el héroe no se rompe: se queda en la portada fija con el póster.

**Nota del 14 de octubre**: el póster va encima del vídeo en el DOM y debe desaparecer solo cuando el
vídeo está listo. Eso lo hace `.stage.listo .poster{opacity:0}` en `styles.css`, y `app.js` quita la
clase `listo` en `desactivar()` para que el póster vuelva si el vídeo se apaga. Sin esa regla el
póster —que es el primer fotograma— tapaba el vídeo para siempre y el scrub parecía una imagen fija.

**Nota del 14 de octubre (tarde)**: el scrub tenía dos huecos que dejaban el héroe muerto en el
póster para el resto de la vida de la pestaña: (1) si la ventana pasaba de ≤768 px a más ancha,
`desactivar()` quitaba el `src` pero el estado seguía `'listo'` y `cargarVideo()` no volvía a
arrancar; (2) un fallo puntual de red o de servidor a la apertura de la pestaña la dejaba en
`'fallo'` eterno. Ahora `desactivar()` devuelve el estado a `'inactivo'` (puede recargar), `alListo()`
ignora cargas que terminan ya en modo estático, y existe `revivir()`: reintento automático (máx. 2)
al recuperar el foco, la conexión o al redimensionar. Ojo: por debajo de 768 px de ancho el scrub se
desactiva **a propósito** y se ve el póster fijo — no es un fallo, ensancha la ventana y vuelve.

### Cómo se hizo el vídeo (14 de octubre de 2026)

**El plan gratuito de la web de Higgsfield no genera vídeo** (comprobado con Seedance 2.0 Mini,
Grok 1.5 Lite y Kling 3.0 Turbo: los tres devuelven `job_minimum_basic_plan_required`), pero **la
API de Higgsfield es facturación aparte** y sí genera. Con una clave de `console.higgsfield.ai`:

1. **Marco inicial** con Seedream 5.0 Flash (2k, 16:9, 0,5 créditos de la web): almendra, nuez y
   arándano deshidratado **partidos**, harina de kañiwa y masa ámbar un escalón más oscura que el
   trigo. Variantes descartadas en `horno-lento-review/`: `marco-inicial-v1- enteros.png` (enteros,
   masa clara) y `marco-inicial-v2-masa-oscura.png` (masa casi cacao).
2. **Subida del marco** a una URL pública con `POST /files/generate-upload-url` (gratis).
3. **Generación**: `POST /bytedance/seedance-2.0/image-to-video` con el prompt de movimiento
   aprobado, `duration: 5`, `resolution: 720p`, `generate_audio: false`. Request
   `4f17f423-d01d-4190-bb7e-67c5acd8f2ed`, completada en 6 minutos.
4. **Coste**: la API factura por tokens — `segundos × ancho × alto × 24 fps ÷ 1024 × 0,014 USD por
   1.000` — es decir **1,51 USD** por 5 s a 720p. Se estima gratis con `POST /estimate/<endpoint>`.
5. **Remate**: el bruto (`horno-lento-review/hero-bruto.mp4`, 5,04 s) seguía bajando por debajo del
   borde del bol en los dos últimos segundos, así que se **recortó a 2,7 s y se congeló el último
   fotograma 2,3 s** (`tpad=stop_mode=clone`). Salida final: 5,00 s exactos, 120 fotogramas,
   keyframes cada 8 imágenes (`-g 8 -keyint_min 8`) para que el scrub busque fotograma a fotograma.
6. `assets/hero-poster.jpg` y `assets/hero-ending.jpg` se extrajeron del vídeo ya cortado. El
   material de relleno anterior quedó respaldado en `horno-lento-review/relleno-hero-*`.

La API **no pone marca de agua**, así que no hizo falta recortar. Los 8,5 créditos del plan web no
se tocaron con el vídeo: salió de la API, que se paga en dólares y caduca al año. El prompt de movimiento
completo, tal y como se envió, está en `horno-lento-review/prompt-movimiento.txt`.

### Las fotos de la galería (14 de octubre de 2026)

Las tres fotos de la sección «Lo que lleva» (`.galeria` en `index.html`) se generaron con
**Seedream 5.0 Flash** desde el plan gratuito (2k, 0,5 créditos cada una), con un único bloque de
estilo fotográfico —lámpara cálida rasante, fondo cacao en penumbra, paleta cocoa-oro-crema— y los
ingredientes escritos a menudo en el prompt: masa de kañiwa y almendra, nuez y arándano **partidos**.

- `assets/foto-cobertura.jpg` — cúpula cargada de frutos partidos (1:1).
- `assets/foto-miga.jpg` — miga ámbar de kañiwa, cortada (1:1).
- `assets/foto-cafe.jpg` — panetone de café, media alta de 900 g (1:1; prompt en
  `horno-lento-review/similares/prompt-d-cafe-v2.txt`).

Los originales PNG de 2k están en `horno-lento-review/similares/` y los prompts en
`prompt-a/b/c/d*.txt` de esa misma carpeta. Para la web se redujeron a 1280 px JPEG
(`ffmpeg -vf scale=1280:1280 -q:v 3`). Saldo tras las cinco generaciones (tres de la galería más
dos versiones del café): **6 créditos**.

### La foto de «El oficio» (14 de octubre de 2026)

La foto anterior de la sección «El oficio» (el bol con los frutos cayendo, un fotograma del
vídeo) se **quitó y se sustituyó** por una imagen propia:

- `assets/foto-amasado.jpg` — manos doblando la masa con almendra, nuez y arándano visibles y el
  horno de obra desenfocado al fondo (16:9, 1280×720, 206 KB). Prompt en
  `horno-lento-review/similares/prompt-g-masa-horno.txt`.

La foto de «El oficio» ocupa **toda la columna** de la derecha (`.oficio__foto` a altura completa
con `object-fit:cover` y `object-position:63% 46%` para no perder el brillo del horno). Sobre el
borde inferior, un velo degradado sostiene el eslogan de la sección (`.oficio__eslogan`,
Fraunces): «Masa madre, frutos secos y tres días de paciencia.», y debajo el pie en mono
(`.oficio__pie`). En pantallas estrechas (≤900 px) la foto vuelve a su proporción natural y el
eslogan y el pie quedan bajo la imagen, sin velo.

Se generaron varias variantes con Seedream 5.0 Flash (0,5 créditos cada una, prompts `prompt-e*`,
`prompt-f*` y `prompt-g*` en `horno-lento-review/similares/`): la del hombre con la masa (`simil-e`),
tres versiones de horno —de caja, de obra y con frutos en la cúpula (`simil-f…v1/v2/v3`)— y la
elegida, la G. Las descartadas quedan guardadas en la misma carpeta. `assets/hero-ending.jpg`
sigue existiendo como fotograma extraído del vídeo, pero ya no lo referencia ningún `<img>`.

Saldo tras las diez generaciones de imágenes (galería, café, oficio): **3,5 créditos**.

### La reserva por WhatsApp (14 de noche)

El formulario de «Reserva» dejó de ser demo: al enviarlo abre **WhatsApp del cliente con el
mensaje ya escrito** (nombre, correo, cantidad, nota y precios). Sin backend, con el enlace
oficial `https://wa.me/<número>?text=...`:

- El número del negocio es una sola constante al inicio de `app.js`:
  `var WHATSAPP = '51925612165';` (código de país + dígitos, sin `+` ni espacios).
- Validación: nombre y correo obligatorios; si falta, no se abre WhatsApp y se marca el error.
- Confirmación: «Se abrió WhatsApp con tu reserva. Confirma el mensaje y envíalo.»
- Se retiraron los avisos de demo del formulario y del pie.
- Para publicar: al no tener backend, el sitio se aloja tal cual en cualquier hosting estático
  (Netlify, Vercel, GitHub Pages). No hay base de datos ni correos: todo el negocio pasa por
  WhatsApp.

---

## 5. Ganchos de prueba

Añadidos a la URL para revisar el sitio sin esperar al scroll:

| Parámetro | Qué hace |
|---|---|
| `?p=0.42` | Fija el héroe en el 42 % del recorrido |
| `?y=3000` | Salta a 3000 px de scroll |
| `?sonda=1` | Muestra una superposición con el estado interno (puertas, errores, vídeo) |
| `?plano=1` | Desactiva las apariciones al entrar en pantalla (para capturas) |
| `?estatico=1` | Fuerza la portada fija |
| `?sinheroe=1` | Oculta el héroe (para revisar las secciones de abajo) |
| `?desplaza=1200` | Sube el contenido 1200 px sin hacer scroll |

---

## 6. Estado y limitaciones conocidas

- Validado en navegador real: héroe, puertas estáticas, maqueta de escritorio y móvil,
  interacción de la masa, formulario (error y éxito), consola limpia y sin desbordes horizontales.
- El formulario **no envía a ningún sitio**: valida en cliente y confirma en pantalla. Para reservas
  reales hay que conectarlo a un servicio (Formspree, una hoja de cálculo, un correo).
- Las reservas no se guardan ni se envía ningún dato a terceros.
- `app.js` incluye ganchos de prueba con `?`. Se pueden borrar sin tocar nada más si el sitio va a
  publicarse.
