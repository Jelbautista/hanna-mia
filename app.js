/* =========================================================
   Horno Lento · motor del héroe de scroll
   Reglas que sostienen la pieza:
   - progreso -> tiempo del vídeo con lerp normalizado por dt
   - un único seek en vuelo, con compuerta
   - escrituras en DOM compuertadas por delta
   - el sitio funciona aunque el vídeo no cargue nunca
   ========================================================= */
(function () {
  'use strict';

  /* ---------------- utilidades ---------------- */
  function q(s, c) { return (c || document).querySelector(s); }
  function qa(s, c) { return Array.prototype.slice.call((c || document).querySelectorAll(s)); }
  function clamp01(x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
  function suave(a, b, x) {
    if (b <= a) { return x >= b ? 1 : 0; }
    var t = clamp01((x - a) / (b - a));
    return t * t * (3 - 2 * t);
  }
  function pseudo(semilla) {
    var s = semilla || 1;
    return function () { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; };
  }

  var errores = [];
  window.addEventListener('error', function (e) { errores.push(String(e.message || e.type)); });
  window.addEventListener('unhandledrejection', function (e) { errores.push('promise: ' + String(e.reason)); });

  /* ---------------- elementos ---------------- */
  var doc = document.documentElement;
  var hero = q('.hero');
  var escena = q('#escenario-scrub');
  var video = q('#video-heroe');
  var posterCapa = q('.poster');
  var cabecera = q('.cabecera');
  var colgado = q('#colgado');
  var oficio = q('#oficio');
  var horasEl = q('#horas');

  if (!hero || !escena || !video) { return; }

  /* ---------------- puertas del héroe estático ---------------- */
  // el scrub también funciona en móvil: solo se apaga por movimiento
  // reducido, datos débiles o fallo (la puerta de ancho quedó abierta a
  // propósito por pedido del cliente)
  var mqAncho = window.matchMedia('(max-width:0px)');
  var mqMov = window.matchMedia('(prefers-reduced-motion: reduce)');
  var mqDatos = window.matchMedia('(prefers-reduced-data: reduce)');
  var redDebil = false;
  var conn = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
  if (conn) {
    if (conn.saveData) { redDebil = true; }
    if (conn.effectiveType && /(^|\D)(2g|slow-2g)($|\D)/.test(conn.effectiveType)) { redDebil = true; }
  }
  var videoRoto = false;
  var modoEstatico = false;
  var forzadoEstatico = false;

  /* ---------------- partir los titulares ---------------- */
  function partir(el, tipo) {
    var texto = el.textContent.replace(/\s+/g, ' ').trim();
    var rand = pseudo(tipo.length * 97 + texto.length * 13 + 7);
    el.textContent = '';

    var oculto = document.createElement('span');
    oculto.className = 'sr';
    oculto.textContent = texto;
    el.appendChild(oculto);

    var visible = document.createElement('span');
    visible.setAttribute('aria-hidden', 'true');
    var palabras = texto.split(' ');

    palabras.forEach(function (palabra, wi) {
      var w = document.createElement('span');
      w.className = 'w';
      var base = palabras.length > 1 ? wi / (palabras.length - 1) : 0;
      w.style.setProperty('--th', (base * 0.26 + rand() * 0.05).toFixed(4));

      palabra.split('').forEach(function (ch, ci) {
        var c = document.createElement('span');
        c.className = 'c';
        c.textContent = ch;
        var thChar = base * 0.26 + (palabra.length > 1 ? ci / (palabra.length - 1) : 0) * 0.07 + rand() * 0.04;
        c.style.setProperty('--th', thChar.toFixed(4));

        if (tipo === 'grid') {
          c.style.setProperty('--gx', ((wi % 2 ? -1 : 1) * (16 + rand() * 34)).toFixed(1) + 'px');
        }
        if (tipo === 'scatter') {
          var ang = rand() * Math.PI * 2;
          var dist = 28 + rand() * 52;
          c.style.setProperty('--jx', (Math.cos(ang) * dist).toFixed(1) + 'px');
          c.style.setProperty('--jy', (Math.sin(ang) * dist).toFixed(1) + 'px');
          c.style.setProperty('--jr', ((rand() * 2 - 1) * 15).toFixed(1) + 'deg');
        }
        w.appendChild(c);
      });

      visible.appendChild(w);
      if (wi < palabras.length - 1) { visible.appendChild(document.createTextNode(' ')); }
    });

    el.appendChild(visible);
  }

  qa('[data-entra]').forEach(function (el) { partir(el, el.getAttribute('data-entra')); });

  /* ---------------- mapa de bandas ---------------- */
  var bandas = qa('.banda').map(function (el) {
    var a = parseFloat(el.getAttribute('data-a'));
    var b = parseFloat(el.getAttribute('data-b'));
    return {
      el: el, a: a, b: b, op: -1, k: -1,
      primera: a <= 0, ultima: b >= 1,
      f: Math.min(0.02, (b - a) / 3),
      ramp: Math.min(0.06, (b - a) * 0.30)
    };
  });

  function opDe(b, p) {
    if (b.primera) { return 1 - suave(b.b - b.f, b.b, p); }
    if (b.ultima) { return suave(b.a, b.a + b.f, p); }
    return suave(b.a, b.a + b.f, p) * (1 - suave(b.b - b.f, b.b, p));
  }
  function kDe(b, p, kCarga) {
    var k = clamp01((p - b.a) / b.ramp);
    if (b.primera) { k = Math.max(k, kCarga); }
    return k;
  }

  var kCarga = 0;
  var rampaCorriendo = false;
  function arrancarRampa() {
    if (rampaCorriendo || modoEstatico) { return; }
    rampaCorriendo = true;
    var t0 = performance.now();
    // con temporizador, no con rAF: la primera pantalla no puede depender de que
    // el navegador repinta (pestañas sin foco o ahorro de batería frenan rAF)
    (function paso() {
      var u = clamp01((performance.now() - t0) / 1150);
      kCarga = 1 - Math.pow(1 - u, 3);
      pintar(actual);
      if (u < 1) { setTimeout(paso, 24); } else { rampaCorriendo = false; }
    })();
  }

  function pintar(p) {
    for (var i = 0; i < bandas.length; i++) {
      var b = bandas[i];
      var op = opDe(b, p);
      if (Math.abs(op - b.op) > 0.004) {
        b.op = op;
        b.el.style.opacity = op.toFixed(3);
        b.el.classList.toggle('on', op > 0.02);
      }
      var k = kDe(b, p, kCarga);
      if (Math.abs(k - b.k) > 0.006) {
        b.k = k;
        b.el.style.setProperty('--k', k.toFixed(3));
      }
    }
  }

  /* ---------------- progreso y bucle ---------------- */
  var objetivo = 0, actual = 0;
  var tsAnterior = 0, corriendo = false;
  var buscando = false, pendiente = false, pendienteT = 0, ultimoT = -1;
  var relojSeek = 0;
  var fijoP = null;

  function progreso() {
    var r = hero.getBoundingClientRect();
    var total = hero.offsetHeight - window.innerHeight;
    if (total <= 0) { return 0; }
    return clamp01(-r.top / total);
  }

  function buscar(p) {
    if (estado !== 'listo') { return; }
    var dur = video.duration;
    if (!dur || !isFinite(dur)) { return; }
    var t = clamp01(p) * (dur - 0.05);
    if (Math.abs(t - ultimoT) <= 0.05) { return; }
    if (buscando) { pendiente = true; pendienteT = t; return; }
    buscarAhora(t);
  }

  function buscarAhora(t) {
    buscando = true; pendiente = false; ultimoT = t;
    clearTimeout(relojSeek);
    try { video.currentTime = t; } catch (e) { buscando = false; return; }
    relojSeek = setTimeout(function () { buscando = false; }, 900);
  }

  video.addEventListener('seeked', function () {
    buscando = false;
    clearTimeout(relojSeek);
    if (pendiente) { pendiente = false; buscarAhora(pendienteT); }
  });

  video.addEventListener('loadedmetadata', function () { apunta('loadedmetadata dur=' + video.duration + ' t=' + Math.round(performance.now())); });
  video.addEventListener('canplay', function () { apunta('canplay t=' + Math.round(performance.now())); });
  video.addEventListener('error', function () { apunta('video-error code=' + (video.error && video.error.code) + ' t=' + Math.round(performance.now())); });
  video.addEventListener('stalled', function () { apunta('stalled t=' + Math.round(performance.now())); });

  function tik(ts) {
    var dt = tsAnterior ? Math.min(0.08, (ts - tsAnterior) / 1000) : 1 / 60;
    tsAnterior = ts;
    actual += (objetivo - actual) * (1 - Math.exp(-dt / 0.10));
    if (Math.abs(objetivo - actual) < 0.0004) { actual = objetivo; }
    pintar(actual);
    buscar(actual);
    if (actual !== objetivo || buscando) {
      requestAnimationFrame(tik);
    } else {
      corriendo = false; tsAnterior = 0;
    }
  }

  /* ---------------- firma: el panetone colgado ---------------- */
  var oficioTop = 0, oficioAlto = 0, dibujo = -1, horasVistas = -1;

  function medir() {
    if (oficio) { oficioTop = oficio.offsetTop; oficioAlto = oficio.offsetHeight; }
  }

  function pintaFirma() {
    if (!colgado || !oficio || !oficioAlto) { return; }
    var y = window.scrollY || window.pageYOffset || 0;
    var vh = window.innerHeight;
    var p = clamp01((y + vh * 0.75 - oficioTop) / (oficioAlto * 0.62));
    if (Math.abs(p - dibujo) <= 0.012) { return; }
    dibujo = p;
    colgado.style.setProperty('--draw', p.toFixed(3));
    var n = Math.round(p * 72);
    if (n !== horasVistas && horasEl) {
      horasVistas = n;
      horasEl.textContent = (n < 10 ? '0' : '') + n;
    }
  }

  if (colgado) {
    qa('path', colgado).forEach(function (pth) {
      var L = 0;
      try { L = pth.getTotalLength(); } catch (e) { L = 0; }
      pth.style.setProperty('--len', (L || 600).toFixed(0));
    });
    if (mqMov.matches) {
      colgado.style.setProperty('--draw', '1');
      if (horasEl) { horasEl.textContent = '72'; }
    }
  }

  /* ---------------- cabecera ---------------- */
  function actualizaCabecera() {
    if (!cabecera) { return; }
    var ver = modoEstatico || actual > 0.9;
    cabecera.classList.toggle('cabecera--oculta', !ver);
  }

  /* ---------------- vida del vídeo ---------------- */
  var SRC = 'assets/hero-scrub.mp4';
  var POSTER = 'assets/hero-poster.jpg';
  var estado = 'inactivo'; // inactivo | cargando | listo | fallo
  var urlPropia = null;
  var relojGuardia = 0;
  var bitacora = [];
  function apunta(txt) { bitacora.push(txt); }

  function prepararPoster() {
    posterCapa.style.backgroundImage = 'url("' + POSTER + '")';
  }

  function intentarSrc(src) {
    return new Promise(function (res, rej) {
      var t = setTimeout(function () { limpiar(); rej(new Error('tiempo')); }, 9000);
      function ok() { clearTimeout(t); limpiar(); res(); }
      function mal() { clearTimeout(t); limpiar(); rej(new Error('decodifica')); }
      function limpiar() {
        video.removeEventListener('loadeddata', ok);
        video.removeEventListener('error', mal);
      }
      video.addEventListener('loadeddata', ok);
      video.addEventListener('error', mal);
      video.preload = 'auto';
      apunta('src:' + src.slice(0, 40) + ' t=' + Math.round(performance.now()));
      video.src = src;
      video.load();
    });
  }

  function alListo() {
    if (estado === 'listo' || modoEstatico) { return; }
    estado = 'listo';
    apunta('listo t=' + Math.round(performance.now()) + ' rs=' + video.readyState + ' dur=' + video.duration);
    clearTimeout(relojGuardia);
    escena.classList.remove('cargando');
    escena.classList.add('listo');
    try { video.pause(); } catch (e) {}
    if (fijoP !== null) { aplicarFijo(); }
    else if (!modoEstatico) { buscar(progreso()); } // si el scroll ya pasó, salta al fotograma actual
  }

  function alFalla() {
    if (estado === 'listo' || estado === 'fallo') { return; }
    estado = 'fallo';
    clearTimeout(relojGuardia);
    escena.classList.remove('cargando');
    videoRoto = true;
    aplicarModo();
    // una pestaña no se queda muerta tras un fallo puntual (p. ej. el servidor
    // caído al abrirla): se reintenta al recuperar el foco o la red
    window.addEventListener('focus', revivir);
    window.addEventListener('online', revivir);
  }

  var reintentos = 0;
  function revivir() {
    if (estado !== 'fallo' || reintentos >= 2) { return; }
    reintentos++;
    apunta('reintento-' + reintentos + ' t=' + Math.round(performance.now()));
    videoRoto = false;
    estado = 'inactivo';
    aplicarModo(); // vuelve a mirar puertas y, si todo va bien, recarga el vídeo
  }

  function cargarVideo() {
    if (estado !== 'inactivo' || modoEstatico) { return; }
    estado = 'cargando';
    prepararPoster();
    escena.classList.add('cargando');
    arrancarRampa();
    relojGuardia = setTimeout(alFalla, 13000);
    apunta('iniciar t=' + Math.round(performance.now()));

    fetch(SRC)
      .then(function (r) {
        apunta('fetch-http ' + r.status + ' len=' + r.headers.get('content-length') +
          ' t=' + Math.round(performance.now()));
        if (!r.ok) { throw new Error('http ' + r.status); }
        var total = parseFloat(r.headers.get('content-length')) || 0;
        if (!r.body || !total) { return r.blob(); }
        var lector = r.body.getReader();
        var trozos = [], recibido = 0;
        function paso() {
          return lector.read().then(function (res) {
            if (res.done) { return new Blob(trozos, { type: 'video/mp4' }); }
            trozos.push(res.value);
            recibido += res.value.length;
            escena.style.setProperty('--ld', (126 * (1 - recibido / total)).toFixed(1));
            return paso();
          });
        }
        return paso();
      })
      .then(function (blob) {
        apunta('blob=' + (blob && blob.size) + ' t=' + Math.round(performance.now()));
        if (blob instanceof Blob) {
          urlPropia = URL.createObjectURL(blob);
          return intentarSrc(urlPropia);
        }
        return intentarSrc(SRC);
      })
      .catch(function (err) {
        apunta('catch ' + String(err && err.message) + ' t=' + Math.round(performance.now()));
        // sin fetch (file://) o fallo de blob: ruta directa
        return intentarSrc(SRC);
      })
      .then(alListo, function (err) {
        apunta('fin-fallo ' + String(err && err.message));
        alFalla();
      });
  }

  function desactivar() {
    clearTimeout(relojGuardia);
    escena.classList.remove('cargando');
    escena.classList.remove('listo');
    if (urlPropia) {
      try { video.pause(); } catch (e) {}
      video.removeAttribute('src');
      try { video.load(); } catch (e) {}
      URL.revokeObjectURL(urlPropia);
      urlPropia = null;
    }
    // al desmontar el vídeo, el estado vuelve a 'inactivo' para poder recargarlo
    // cuando la ventana vuelva a ser ancha (si no, quedaba 'listo' y muerto)
    if (estado === 'listo' || estado === 'cargando') { estado = 'inactivo'; }
    for (var i = 0; i < bandas.length; i++) { bandas[i].op = -1; bandas[i].k = -1; }
    pintar(1); // estados finales de diseño, fijados
  }

  function aplicarModo() {
    var est = forzadoEstatico || mqAncho.matches || mqMov.matches || mqDatos.matches || redDebil || videoRoto;
    modoEstatico = est;
    doc.classList.toggle('sin-video', est);
    if (est) {
      desactivar();
    } else {
      cargarVideo();
    }
    actualizaCabecera();
  }

  /* ---------------- gancho de prueba (?p= y ?sonda=) ---------------- */
  var params = null;
  try { params = new URLSearchParams(location.search); } catch (e) { params = null; }
  var plano = !!(params && params.has('plano'));
  forzadoEstatico = !!(params && params.has('estatico'));
  if (params && params.has('sinheroe')) { hero.style.display = 'none'; }
  if (params && params.has('desplaza')) {
    // desplaza el contenido sin hacer scroll (las capturas de headless se hacen en negro al scrollear)
    var despl = parseInt(params.get('desplaza'), 10) || 0;
    var principal = q('main');
    if (principal && despl > 0) { principal.style.marginTop = (-despl) + 'px'; }
  }

  function aplicarFijo() {
    if (fijoP === null) { return; }
    objetivo = actual = fijoP;
    pintar(actual);
    buscar(actual);
  }

  if (params && params.has('p')) {
    fijoP = clamp01(parseFloat(params.get('p')) || 0);
    window.scrollTo(0, 0);
    setTimeout(aplicarFijo, 0);
    setTimeout(aplicarFijo, 1800);
    setTimeout(aplicarFijo, 3500);
  }

  if (params && params.has('y')) {
    var yv = parseInt(params.get('y'), 10) || 0;
    var fijarY = function () { window.scrollTo({ top: yv, behavior: 'instant' }); };
    setTimeout(fijarY, 120);
    setTimeout(fijarY, 1500);
    setTimeout(fijarY, 3500);
  }

  function hacerSonda(fin) {
    var salida = {
      finScript: !!fin,
      busca: location.search,
      errores: errores,
      modo: doc.className,
      puertas: {
        ancho: mqAncho.matches,
        movimiento: mqMov.matches,
        datos: mqDatos.matches,
        redDebil: redDebil,
        videoRoto: videoRoto
      },
      video: {
        estado: estado,
        readyState: video.readyState,
        duracion: +(video.duration || 0).toFixed(2),
        error: (video.error && video.error.code) || 0,
        bitacora: bitacora
      },
      altoHeroeVh: +(hero.offsetHeight / window.innerHeight).toFixed(2),
      desbordeX: doc.scrollWidth - window.innerWidth,
      altoDocumento: document.body.scrollHeight,
      scrollY: Math.round(window.scrollY || 0),
      recursos: performance.getEntriesByType('resource').length,
      imagenes: [].map.call(document.images, function (im) {
        return ((im.currentSrc || im.src) || '').split('/').pop() + '=' + im.naturalWidth;
      }),
      poster: posterCapa ? (posterCapa.style.backgroundImage || 'vacio').slice(0, 46) : 'sin',
      geo: (function () {
        var c = document.getElementById('colgado');
        if (!c) { return 'sin-colgado'; }
        var r = c.getBoundingClientRect();
        var e = c.parentNode;
        var sv = c.querySelector('svg');
        var rs = sv ? sv.getBoundingClientRect() : null;
        return {
          padre: String(e.className || e.tagName).slice(0, 30),
          caja: [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)].join('x'),
          svg: rs ? [Math.round(rs.left), Math.round(rs.top), Math.round(rs.width), Math.round(rs.height)].join('x') : 'sin',
          display: getComputedStyle(c).display,
          col: getComputedStyle(c).gridColumnStart + '..' + getComputedStyle(c).gridColumnEnd,
          fila: getComputedStyle(c).gridRowStart + '..' + getComputedStyle(c).gridRowEnd
        };
      })(),
      revelar: (function () {
        var t = qa('.revelar'), v = qa('.revelar.visible');
        var muestra = t.slice(0, 3).map(function (el) {
          var cs = getComputedStyle(el);
          return (el.className.split(' ')[0]) + '|vis=' + el.classList.contains('visible') + '|op=' + cs.opacity;
        });
        return { total: t.length, visibles: v.length, muestra: muestra };
      })(),
      secciones: (function () {
        var m = {};
        qa('main section, footer').forEach(function (s) { m[s.id || s.className] = Math.round(s.offsetTop); });
        return m;
      })(),
      bandas: []
    };

    [0.05, 0.3, 0.5, 0.7, 0.93, 1].forEach(function (p) {
      var fila = { p: p, visibles: [] };
      bandas.forEach(function (b) {
        if (opDe(b, p) > 0.5) {
          fila.visibles.push(b.el.className.replace('banda ', '').replace(' on', ''));
        }
      });
      salida.bandas.push(fila);
    });

    salida.kFinal = bandas.map(function (b) { return +kDe(b, 1, 1).toFixed(2); });
    var antes = actual;
    actual = 0.95; actualizaCabecera();
    salida.cabeceraEn095 = cabecera.className;
    actual = 0; actualizaCabecera();
    salida.cabeceraEn0 = cabecera.className;
    actual = antes;

    var previo = document.getElementById('sonda-salida');
    if (previo && previo.parentNode) { previo.parentNode.removeChild(previo); }

    var pre = document.createElement('pre');
    pre.id = 'sonda-salida';
    pre.style.cssText = 'position:fixed;left:0;top:0;right:0;z-index:9999;margin:0;padding:12px ' +
      '14px;background:#050505;color:#7CFF9B;font:12px/1.45 ui-monospace,Consolas,monospace;' +
      'white-space:pre-wrap;word-break:break-word;max-height:100vh;overflow:auto';
    pre.textContent = JSON.stringify(salida, null, 1);
    document.body.appendChild(pre);
  }

  if (params && params.has('sonda')) {
    setTimeout(hacerSonda, 500);
    setTimeout(hacerSonda, 9000);
    window.addEventListener('load', function () { setTimeout(hacerSonda, 3000); });
  }

  /* ---------------- revelados de abajo del pliegue ---------------- */
  var SEL = '.seccion .kicker, .seccion .titulo, .seccion .entradilla, .seccion .destacado, ' +
            '.seccion .oficio__cuerpo, .seccion .tres > li, .seccion .tina, .seccion .pulsa, ' +
            '.seccion .aviso, .seccion dl, .seccion .formulario, .seccion figure';

  if ('IntersectionObserver' in window && !mqMov.matches && !plano) {
    var io = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (e) {
        if (!e.isIntersecting) { return; }
        e.target.classList.add('visible');
        io.unobserve(e.target);
      });
    }, { rootMargin: '0px 0px -12% 0px', threshold: 0.12 });

    qa('.seccion').forEach(function (sec) {
      qa(SEL, sec).forEach(function (el, i) {
        el.style.setProperty('--i', i);
        el.classList.add('revelar');
        io.observe(el);
      });
    });
    qa('.pasos').forEach(function (el) { io.observe(el); });
  } else if (plano) {
    // ?plano=1: sin animación de entrada, todo a la vista (capturas de QA)
    qa('.pasos').forEach(function (el) { el.classList.add('visible'); });
  }

  /* ---------------- momento interactivo ---------------- */
  var pulsa = q('#pulsa'), masa = q('#masa'), aviso = q('#masa-aviso'), revelado = q('#masa-revelado');
  if (pulsa && masa) {
    var prog = 0, sostenido = false, rafMasa = 0, tsMasa = 0, hecho = false;

    function pasoMasa(ts) {
      var dt = tsMasa ? Math.min(0.06, (ts - tsMasa) / 1000) : 1 / 60;
      tsMasa = ts;
      prog = clamp01(prog + (sostenido ? dt / 1.5 : -dt / 0.9));
      masa.style.setProperty('--p', prog.toFixed(3));
      if (aviso) {
        aviso.textContent = prog >= 1 ? 'Masa lista' : 'Al ' + Math.round(prog * 100) + ' %';
      }
      if (prog >= 1 && !hecho) {
        hecho = true;
        if (revelado) { revelado.hidden = false; setTimeout(function () { revelado.classList.add('visible'); }, 30); }
      }
      if (prog > 0 || sostenido) {
        rafMasa = requestAnimationFrame(pasoMasa);
      } else {
        rafMasa = 0; tsMasa = 0;
      }
    }
    function arrancarMasa() {
      sostenido = true;
      if (!rafMasa) { rafMasa = requestAnimationFrame(pasoMasa); }
    }
    function soltarMasa() { sostenido = false; }

    pulsa.addEventListener('pointerdown', function (e) { e.preventDefault(); arrancarMasa(); });
    pulsa.addEventListener('pointerup', soltarMasa);
    pulsa.addEventListener('pointercancel', soltarMasa);
    pulsa.addEventListener('pointerleave', soltarMasa);
    pulsa.addEventListener('keydown', function (e) {
      if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); arrancarMasa(); }
    });
    pulsa.addEventListener('keyup', function (e) {
      if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); soltarMasa(); }
    });
    pulsa.addEventListener('blur', soltarMasa);
  }

  /* ---------------- reserva por WhatsApp ---------------- */
  // Número de Hanna Mia CON código de país (Perú: 51), solo dígitos.
  // Cambia este valor por el número real del negocio; nada más hay que tocar.
  var WHATSAPP = '51925612165';

  /* ---------------- formulario ---------------- */
  var form = q('#formulario');
  if (form) {
    var ok = q('#formulario-ok');
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var nombre = q('#nombre').value.trim();
      var correo = q('#correo').value.trim();
      var cantidad = q('#cantidad') ? q('#cantidad').value : '1';
      var nota = q('#nota') ? q('#nota').value.trim() : '';
      var bueno = /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(correo);
      if (!nombre || !bueno) {
        if (ok) {
          ok.hidden = false;
          ok.classList.add('error');
          ok.textContent = 'Falta tu nombre o el correo no es válido.';
        }
        (!nombre ? q('#nombre') : q('#correo')).focus();
        return;
      }
      var lineas = [
        'Hola Hanna Mia, quiero reservar mi panetón:',
        '',
        'Nombre: ' + nombre,
        'Correo: ' + correo,
        'Cantidad: ' + cantidad,
        nota ? 'Nota: ' + nota : '',
        '',
        'Panetón artesanal de 900 g. Preventa S/ 35, precio regular S/ 45.'
      ];
      var url = 'https://wa.me/' + WHATSAPP + '?text=' + encodeURIComponent(lineas.join('\n'));
      window.open(url, '_blank');
      if (ok) {
        ok.hidden = false;
        ok.classList.remove('error');
        ok.textContent = 'Se abrió WhatsApp con tu reserva. Confirma el mensaje y envíalo.';
      }
      form.reset();
    });
  }

  /* ---------------- eventos ---------------- */
  function alScroll() {
    pintaFirma();
    if (modoEstatico) { return; }
    if (fijoP === null) { objetivo = progreso(); }
    actualizaCabecera();
    if (!corriendo) { corriendo = true; tsAnterior = 0; requestAnimationFrame(tik); }
  }

  var relojResize = 0;
  function alResize() {
    clearTimeout(relojResize);
    relojResize = setTimeout(function () {
      medir();
      aplicarModo();
      revivir(); // si la última vida terminó en fallo, se reintenta al cambiar de tamaño
      alScroll();
    }, 150);
  }

  window.addEventListener('scroll', alScroll, { passive: true });
  window.addEventListener('resize', alResize);
  window.addEventListener('orientationchange', alResize);
  window.addEventListener('load', function () { medir(); alScroll(); });

  document.addEventListener('visibilitychange', function () {
    if (document.hidden) {
      if (corriendo) { corriendo = false; tsAnterior = 0; }
      clearTimeout(relojSeek);
      buscando = false;
      try { video.pause(); } catch (e) {}
    } else {
      alScroll();
    }
  });

  /* ---------------- arranque ---------------- */
  medir();
  aplicarModo();
  pintar(0);
  pintaFirma();
  actualizaCabecera();
  if (params && params.has('sonda')) {
    try {
      hacerSonda(true);
    } catch (e) {
      var pFallo = document.createElement('pre');
      pFallo.id = 'sonda-fallo';
      pFallo.style.cssText = 'position:fixed;left:0;top:0;right:0;z-index:99999;margin:0;padding:14px;' +
        'background:#2a0808;color:#ffd7d7;font:12px/1.45 ui-monospace,Consolas,monospace;white-space:pre-wrap';
      pFallo.textContent = 'FALLO EN LA SONDA: ' + ((e && e.stack) || e);
      document.body.appendChild(pFallo);
    }
  }
})();
