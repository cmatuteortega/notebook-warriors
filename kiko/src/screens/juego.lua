-- La pantalla de juego: el tablero, el dedo y toda la coreografia.
--
-- Aqui NO hay reglas. Las reglas estan en `src/board.lua`, que no dibuja; esta
-- pantalla coge los sucesos que devuelve el tablero y les pone tiempo encima.
-- La frontera es esa y conviene respetarla: si te ves preguntando "cuantas
-- galletas hacen falta para una envuelta" en este archivo, la pregunta va en el
-- otro.
--
-- La cascada entera se escribe como una CORRUTINA (`src/director.lua`), de
-- arriba abajo y con esperas por el medio, porque es literalmente una
-- secuencia: rompe, apaga, cae, aterriza, vuelve a mirar. Mientras corre, el
-- tablero no admite dedos.
--
-- Una PIEZA es lo que se ve; una CELDA es lo que hay en el tablero. Se
-- relacionan por el `id` que pone `board.lua` y que no se reutiliza nunca:
-- sin el, dos galletas del mismo color que se cruzan en una columna se
-- intercambian el sprite a media caida y no hay forma de verlo venir.

local Constants = require("src.constants")
local Palette   = require("src.palette")
local Board     = require("src.board")
local Levels    = require("src.levels")
local Arcade    = require("src.arcade")
local Puntuacion = require("src.puntuacion")
local Pizarra   = require("src.pizarra")
local Art       = require("src.art")
local UI        = require("src.ui")
local Hud       = require("src.hud")
local Kiko      = require("src.kiko")
local Efectos   = require("src.efectos")
local Particles = require("src.particles")
local Director  = require("src.director")
local Session   = require("src.session")
local Sfx       = require("src.sfx")
local flux      = require("lib.flux")
local ScreenManager = require("lib.screen_manager")

local Juego = {}

--== Tiempos ===============================================================
--
-- Todos los tiempos del juego en un sitio. Estan medidos a dedo puesto y no
-- son gusto: son el limite por debajo del cual la animacion deja de contarse
-- (no se entiende que ha pasado) y por encima del cual el juego se arrastra.
-- Ver README.md antes de tocarlos.
local T_SWAP   = 0.15    -- lo que tarda un intercambio
local T_VUELTA = 0.13    -- y lo que tarda en deshacerse si no valia
local T_POP    = 0.20    -- crecer y reventar
local T_ONDA   = 0.13    -- entre una onda de explosiones y la siguiente
local T_CAIDA  = 0.052   -- por casilla de caida
local T_MIN    = 0.13    -- ninguna caida dura menos que esto
local T_POSO   = 0.06    -- respiro entre que aterriza todo y se vuelve a mirar
-- El viaje de un trozo de estrella, y lo que tarda el siguiente en salir. Los
-- dos estan medidos contra lo mismo: el ojo tiene que poder SEGUIR uno de los
-- tres de punta a punta. Por debajo de 0,3 s el viaje se ve como un
-- parpadeo en dos sitios, y por encima de 0,4 s la jugada entera se para a
-- mirar como vuela una estrella. El paso de 0,07 s es lo que hace que se
-- lean tres salidas y no una rafaga.
local T_ESTRELLA = 0.34
local T_PASO_ESTRELLA = 0.07
local OCIO_PISTA = 5.0   -- segundos parado antes de ensenar una jugada
-- Y lo que Kiko aguanta sin que se case nada antes de bostezar. Se cuenta
-- desde la ultima jugada BUENA y no desde el ultimo toque: quien esta
-- probando galletas que no casan tampoco esta jugando, y el perro es el unico
-- sitio del juego que puede decirlo sin un cartel. Va despues de la pista (a
-- los cinco segundos) a proposito: primero se ayuda, y si aun asi no pasa
-- nada, el perro se aburre.
local T_BOSTEZO = 10.0

-- El faldon del bol: la franja de acero que sobresale por debajo del tablero y
-- que lleva grabado el nombre. Catorce pixeles de arte son cincuenta y seis
-- virtuales, y descontando el reborde queda sitio para la fuente mediana con
-- aire arriba y abajo; con menos, la letra toca los dos cantos y el faldon se
-- lee como una etiqueta pegada en vez de como parte del bol.
local FALDON = 14

local T = Constants.TILE

-- `run` es la partida de arcade, y es lo UNICO que distingue los dos modos
-- desde aqui: con ella, el nivel lo pone el arcade y el final lleva a la
-- pausa de las mejoras; sin ella, todo es exactamente lo de antes. No hay un
-- "modo" apuntado en ningun sitio -- preguntar por la partida es preguntar por
-- el modo, y asi no pueden contradecirse.
local board, def, numero, run
local piezas, moribundas, particulas
local ox, oy, faldon
local progreso, movimientos, estado
local seleccion, arrastre, ocioso, pista
local cascadaMaxima
-- El perro y las dos cosas con las que se elige su cara: lo que llevaba el bol
-- al empezar (para saber cuanto falta de lo que se pide limpiar) y el rato que
-- lleva sin casarse nada.
local kiko, inicial, sinJugada

-- La puntuacion del arcade (Base x Mult, `src/puntuacion.lua`). `puntEstado` es
-- lo que recuerda la ronda entre movimientos (escalada y afinidad),
-- `puntMods` las mejoras de la partida y `enCurso` el movimiento que se esta
-- contando: se llena suceso a suceso mientras cae la cascada y se cobra UNA
-- vez, cuando el tablero se ha quedado quieto. En la campana los tres son nil
-- y todo puntua como siempre.
local puntEstado, puntMods, enCurso

-- La pregunta de dejar el nivel, y el perro que la hace. Es un SEGUNDO perro y
-- no el de la cabecera: es el unico sitio del juego donde se ven dos a la vez,
-- y a proposito. El de arriba sigue contando como va la partida detras del
-- velo -- es lo que se esta a punto de tirar --; este mira de frente y
-- pregunta. Con uno solo habria que quitarle su animo a la cabecera mientras
-- dura la pregunta, y al decir que no el perro volveria distinto de como
-- estaba.
local confirmar, dudoso

-- Se declaran aqui y se escriben abajo, con el dibujo: la tecla de atras y el
-- boton de salir hacen lo MISMO (levantar la pregunta), y la tecla se lee mil
-- lineas antes que el boton. `abandonar` es lo que pasa cuando se contesta que
-- si: apuntar la marca del arcade y volver.
local abandonar, pedirSalir, previsualizar

--== Piezas ================================================================

local function centro(i)
    local c, r = board:cr(i)
    return ox + (c - 0.5) * T, oy + (r - 0.5) * T
end

local function spriteDe(p)
    if p.pastilla then return "pastilla" end
    return Art.idGalleta(p.color, p.especial)
end

local function crearPieza(celda, i, desde)
    local x, y = centro(i)
    local p = {
        id = celda.id, color = celda.color, especial = celda.especial, pastilla = celda.pastilla,
        hielo = celda.hielo,
        x = x, y = desde or y, ex = 1, ey = 1,
    }
    piezas[celda.id] = p
    return p
end

-- Pone al dia color y especial de todo lo que sigue en el tablero. Hace falta
-- porque `resolver` cambia cosas EN EL SITIO -- una galleta se convierte en
-- rayada sin moverse, y la pelota con especial convierte medio tablero --
-- y la pieza tiene que enterarse sin que nadie la mueva.
local function refrescar()
    for i = 1, board.cols * board.rows do
        local celda = board.celdas[i]
        if celda then
            local p = piezas[celda.id]
            if not p then
                p = crearPieza(celda, i)
            else
                p.color, p.especial, p.pastilla = celda.color, celda.especial, celda.pastilla
                p.hielo = celda.hielo
            end
        end
    end
end

-- La galleta que se rompe: fogonazo blanco, crece, revienta y suelta migas.
-- Crecer ANTES de desaparecer es lo que convierte un "ha desaparecido" en un
-- "la he roto": sin ese pellizco de 0,1 s el tablero parece que se corrige
-- solo.
local function matar(id, color, especial)
    local p = piezas[id]
    if not p then return end
    piezas[id] = nil
    moribundas[#moribundas + 1] = p

    Efectos.destello(p.x, p.y, spriteDe(p))
    local c = color and Palette.galletas[color] and Palette.galletas[color].base or Palette.miga
    particulas:estallido(p.x, p.y, especial and 10 or 6, c, especial and 1.5 or 1)

    flux.to(p, T_POP * 0.45, { ex = 1.5, ey = 1.5 }):ease("quadout")
        :after(p, T_POP * 0.55, { ex = 0, ey = 0 }):ease("quadin")
end

-- El cubito que no se deja mover: TIEMBLA. Es importante que no haga lo mismo
-- que una jugada que no vale (irse y volver): irse y volver dice "ese cambio
-- no casa nada", y lo que pasa aqui es otra cosa -- esa galleta no se puede
-- tocar todavia. Un temblor corto en el sitio es lo que dice eso sin texto.
local function tiritar(p)
    if not p then return end
    local x = p.x
    flux.to(p, 0.05, { x = x + 2 }):ease("quadout")
        :after(p, 0.05, { x = x - 2 })
        :after(p, 0.05, { x = x })
    Sfx.play("nada", 1.4, 0.5)
end

-- Hacer algo dentro de un rato. Se apoya en flux y no en un temporizador
-- propio porque flux ya lo lleva todo -- y sobre todo porque main.lua lo para
-- con el juego: un reloj aparte seguiria contando con el nivel ya cerrado.
local function tras(segundos, fn)
    flux.to({ t = 0 }, segundos, { t = 1 }):oncomplete(fn)
end

--== Efectos de las especiales =============================================

local function colorDe(indice)
    local fam = indice and Palette.galletas[indice]
    return fam and fam.base or Palette.miga
end

-- El reparto de una estrella: cuando sale cada trozo, cuando llega y por que
-- lado hace el arco.
--
-- Es una sola funcion porque son dos sitios los que tienen que estar de
-- acuerdo -- quien dibuja el viaje y quien revienta lo que hay al final -- y
-- si cada uno se lo calculara por su cuenta, la galleta reventaria antes o
-- despues de que llegue su estrella. Eso no se ve como un desajuste de
-- milesimas: se ve como que la estrella no ha hecho nada.
local function vueloEstrella(f)
    local out = {}
    for k, destino in ipairs(f.destinos or {}) do
        local salida = (k - 1) * T_PASO_ESTRELLA
        out[#out + 1] = {
            i = destino, salida = salida, llegada = salida + T_ESTRELLA,
            -- El arco alterna de lado y se abre mas con cada trozo: tres
            -- curvas iguales desde la misma casilla se pisan y no se puede
            -- seguir ninguna.
            curva = (k % 2 == 0 and -1 or 1) * T * (0.9 + k * 0.35),
        }
    end
    return out
end

local function efectoFuente(f)
    local x, y = centro(f.i)
    local color = colorDe(f.color)

    if f.tipo == "rayaH" or f.tipo == "cruz" or f.tipo == "cruzGorda" then
        Efectos.rayo(x, y, true, color, board.cols * T)
        particulas:chispa(x, y, 1, 0, 10, color)
        particulas:chispa(x, y, -1, 0, 10, color)
        Sfx.play("rayo", 1.0)
    end
    if f.tipo == "rayaV" or f.tipo == "cruz" or f.tipo == "cruzGorda" then
        Efectos.rayo(x, y, false, color, board.rows * T)
        particulas:chispa(x, y, 0, 1, 10, color)
        particulas:chispa(x, y, 0, -1, 10, color)
        Sfx.play("rayo", 1.18)
    end
    if f.tipo == "envuelta" or f.tipo == "bombazo" then
        Efectos.onda(x, y, T * (f.tipo == "bombazo" and 2.8 or 1.8), color)
        Efectos.temblar(f.tipo == "bombazo" and 3 or 1.6)
        Sfx.play("bum", f.tipo == "bombazo" and 0.8 or 1)
        Sfx.vibrar(0.02)
    end
    if f.tipo == "estrella" then
        -- La estrella no revienta un area: se PARTE. Un anillo corto en su
        -- casilla -- para que se vea de donde salen -- y tres trozos que se
        -- van cada uno por su lado, con su chispa y su nota. Las notas suben
        -- una por trozo: es lo que convierte tres bultos moviendose en una,
        -- dos y tres.
        Efectos.onda(x, y, T * 1.1, color)
        Efectos.temblar(1.2)
        Sfx.vibrar(0.02)
        for k, vuelo in ipairs(vueloEstrella(f)) do
            local dx, dy = centro(vuelo.i)
            local largo = math.max(1, math.sqrt((dx - x) ^ 2 + (dy - y) ^ 2))
            Efectos.cometa(x, y, dx, dy, color, vuelo.salida, T_ESTRELLA, vuelo.curva)
            tras(vuelo.salida, function()
                particulas:chispa(x, y, (dx - x) / largo, (dy - y) / largo, 6, color)
                Sfx.play("estrella", 1 + (k - 1) * 0.16)
            end)
        end
    end
    if f.tipo == "pelota" or f.tipo == "color" or f.tipo == "todo" then
        Efectos.onda(x, y, T * 5, color)
        Efectos.temblar(3)
        Sfx.play("pelota")
        Sfx.vibrar(0.04)
    end
    if f.tipo == "cruzGorda" then
        Efectos.temblar(3)
        Sfx.vibrar(0.03)
    end
end

--== Objetivo ==============================================================

local function apuntarRotas(onda)
    for _, c in ipairs(onda.celdas) do
        if c.color then
            progreso.recogidos[c.color] = (progreso.recogidos[c.color] or 0) + 1
        end
    end
end

-- El objetivo de MAS de una ronda glotona. Sin el, `true`: un nivel que no
-- pide nada de mas ya lo tiene hecho.
local function extraCumplido()
    for _, e in ipairs(def.extra or {}) do
        if e.tipo == "pastillas" and board.pastillasRecogidas < e.n then return false end
        if e.tipo == "barro" and board:barroVivo() > 0 then return false end
        if e.tipo == "hielo" and board:hieloVivo() > 0 then return false end
        if e.tipo == "moho" and board:mohoVivo() > 0 then return false end
    end
    return true
end

local function objetivoCumplido()
    local o = def.objetivo
    if not extraCumplido() then return false end
    if o.tipo == "puntos" then
        return progreso.puntos >= o.meta
    elseif o.tipo == "barro" then
        return board:barroVivo() == 0
    elseif o.tipo == "pastillas" then
        return board.pastillasRecogidas >= o.n
    elseif o.tipo == "recoger" then
        for _, pide in ipairs(o.lista) do
            if (progreso.recogidos[pide.color] or 0) < pide.n then return false end
        end
        return true
    end
    return false
end

-- Lo que le falta al nivel, de uno (recien empezado) a cero (hecho). Es lo que
-- mira el perro para ponerse nervioso, y no hay ningun otro sitio que lo pida:
-- la cabecera cuenta cada cosa por separado -- capas de barro, pastillas,
-- galletas de cada color -- porque eso es lo que hay que hacer, y esto es otra
-- pregunta, la de cuanto queda de TODO junto.
--
-- Se mide contra el objetivo y no contra la barra de hambre. La barra son
-- puntos, y en un nivel de barro los puntos pueden ir llenos con el bol
-- todavia sucio: un perro celebrando encima de una barra llena mientras al
-- jugador le queda medio tablero por fregar seria el perro mintiendo.
--
-- Y de lo que pide el nivel se coge lo PEOR, no la media: un nivel que pide
-- limpiar el barro y darle tres pastillas no esta al noventa por ciento
-- porque el barro lo este -- esta a lo que le falte a la pastilla.
--
-- Un tipo de extra nuevo se atiende aqui tambien, con los otros tres sitios
-- que lo piden (`extraCumplido` justo arriba, `Hud.objetivo` y
-- `Levels.textoObjetivo`).
local function resto(queda, total)
    if total <= 0 then return 0 end
    return math.max(0, math.min(1, queda / total))
end

local function falta()
    local o = def.objetivo
    local peor = 0

    if o.tipo == "puntos" then
        peor = resto(o.meta - progreso.puntos, o.meta)
    elseif o.tipo == "barro" then
        peor = resto(progreso.barro, inicial.barro)
    elseif o.tipo == "pastillas" then
        peor = resto(o.n - progreso.pastillas, o.n)
    elseif o.tipo == "recoger" then
        local faltan, piden = 0, 0
        for _, pide in ipairs(o.lista) do
            faltan = faltan + math.max(0, pide.n - (progreso.recogidos[pide.color] or 0))
            piden = piden + pide.n
        end
        peor = resto(faltan, piden)
    end

    for _, e in ipairs(def.extra or {}) do
        local f = 0
        if e.tipo == "pastillas" then f = resto(e.n - progreso.pastillas, e.n)
        elseif e.tipo == "barro" then f = resto(progreso.barro, inicial.barro)
        elseif e.tipo == "hielo" then f = resto(progreso.hielo or 0, inicial.hielo)
        -- El moho es el unico que puede CRECER: `resto` lo corta en uno, asi
        -- que una mancha que se extiende no pone al perro mas nervioso de lo
        -- que estaba al empezar, que es justo lo que no tiene que hacer.
        elseif e.tipo == "moho" then f = resto(progreso.moho or 0, inicial.moho) end
        peor = math.max(peor, f)
    end

    return peor
end

-- El animo del perro, de lo urgente a lo tranquilo. Es lo UNICO que esta
-- pantalla le cuenta a `src/kiko.lua`: alli estan las caras y su reloj, aqui
-- las preguntas -- que son las mismas que se hace el jugador mirando la
-- cabecera, y en el mismo orden.
--
-- El ultimo movimiento manda por encima de todo lo demas: quedarse a un
-- movimiento es lo que cambia la jugada siguiente, y ganar por poco tambien se
-- puede perder.
--
-- Lo de abajo son DOS preguntas y no cuatro casos: si esta pasando algo o no
-- (`sinJugada`), y si el bol va por la mitad o casi lleno (`falta`). La segunda
-- elige version en las dos filas y siempre por lo mismo -- con hambre el perro
-- espera, lleno se relaja --: jugando da `quieto` o `nervioso`, y en un rato
-- muerto da `bostezo` o `dormido`.
local CERCA = 0.30

local function animoDeKiko()
    if estado == "ganado" then return "gana" end
    if estado == "perdido" then return "fallo" end
    if movimientos <= 1 then return "ultimo" end

    local lleno = falta() <= CERCA
    if sinJugada >= T_BOSTEZO then return lleno and "dormido" or "bostezo" end
    -- `reposo` y no `quieto`: lo que se pide es el ESTADO, y el parpadeo se lo
    -- da el propio animo cada cinco segundos (ver `src/kiko.lua`).
    return lleno and "nervioso" or "reposo"
end

--== Animaciones ===========================================================

local function esperarTweens(duracion)
    Director.esperar(duracion)
end

-- Una onda de explosiones: primero lo que dispara (los rayos salen de su
-- casilla antes de que muera nada) y luego lo que muere.
--
-- Devuelve lo que hay que esperar de mas antes de la onda siguiente. Casi
-- siempre es cero: lo unico que lo sube es la estrella, que se lleva por
-- delante casillas a las que todavia esta VOLANDO.
local function animarOnda(onda, cascada)
    -- Lo que una estrella tiene reservado no muere con la onda: muere cuando
    -- llega su trozo. Sin esto, el tablero revienta las tres casillas en el
    -- mismo fotograma en que salen las estrellas y el viaje se convierte en
    -- adorno -- tres luces que cruzan un hueco que ya estaba vacio.
    local aplazadas, retardo = {}, 0
    for _, f in ipairs(onda.fuentes) do
        for _, vuelo in ipairs(vueloEstrella(f)) do
            aplazadas[vuelo.i] = math.max(aplazadas[vuelo.i] or 0, vuelo.llegada)
            retardo = math.max(retardo, vuelo.llegada)
        end
    end

    for _, f in ipairs(onda.fuentes) do efectoFuente(f) end

    for _, c in ipairs(onda.celdas) do
        local espera = aplazadas[c.i]
        if espera then
            -- El aterrizaje del trozo: revienta la galleta y deja su anillo.
            -- El anillo es lo que dice que ha sido la estrella y no la casilla
            -- rompiendose sola.
            tras(espera, function()
                local x, y = centro(c.i)
                Efectos.onda(x, y, T * 0.9, colorDe(c.color))
                Efectos.temblar(0.9)
                matar(c.id, c.color, c.especial)
                Sfx.cascada(cascada)
            end)
        else
            matar(c.id, c.color, c.especial)
        end
    end

    for _, i in ipairs(onda.barro or {}) do
        local x, y = centro(i)
        local espera = aplazadas[i]
        if espera then
            tras(espera, function() particulas:estallido(x, y, 5, Palette.barro, 0.7) end)
        else
            particulas:estallido(x, y, 5, Palette.barro, 0.7)
        end
    end

    -- El moho que se ha limpiado en esta onda. Mismas migas que el barro y mas
    -- fuertes: el barro se queda quieto cuando lo limpias y del moho hay que
    -- ver que SALTA, porque es lo que el jugador esta persiguiendo.
    for _, i in ipairs(onda.moho or {}) do
        local x, y = centro(i)
        local espera = aplazadas[i]
        local function limpiar()
            particulas:estallido(x, y, 8, Palette.mohoLite, 1.0)
            Sfx.play("toque", 1.45, 0.5)
        end
        if espera then tras(espera, limpiar) else limpiar() end
    end

    -- Los cubitos que se han roto en esta onda. Se descongela la PIEZA (por
    -- id, como todo lo demas) y la galleta pega un respingo: el cubito no se ve
    -- desaparecer, se ve SOLTAR lo que tenia dentro, que es lo que el jugador
    -- ha ganado con la jugada.
    for _, h in ipairs(onda.hielo or {}) do
        local x, y = centro(h.i)
        local function romper()
            local p = piezas[h.id]
            if p then
                p.hielo = nil
                p.ex, p.ey = 1.3, 0.78
                flux.to(p, 0.22, { ex = 1, ey = 1 }):ease("backout")
            end
            particulas:estallido(x, y, 9, Palette.hielo, 1.3)
            Efectos.destello(x, y, "hielo")
            Sfx.play("hielo", 0.92 + love.math.random() * 0.18)
        end
        -- Un cubito al que va una estrella espera igual que una galleta: el
        -- cristal tiene que sonar cuando llega el golpe, no cuando sale.
        local espera = aplazadas[h.i]
        if espera then tras(espera, romper) else romper() end
    end

    if #onda.celdas > 0 then
        -- El pop de la onda solo si algo muere AHORA. Lo que espera a una
        -- estrella se lo lleva el suyo al aterrizar, y adelantarlo aqui seria
        -- oir romperse una galleta que todavia esta entera.
        local ahora = 0
        for _, c in ipairs(onda.celdas) do
            if not aplazadas[c.i] then ahora = ahora + 1 end
        end
        if ahora > 0 then
            Sfx.cascada(cascada)
            Efectos.temblar(math.min(2, ahora / 8))
        end
    end

    -- Un pelin mas de lo que dura el viaje. flux corre con el `dt` recortado a
    -- 1/20 de main.lua y el director con el de verdad, asi que en un tiron los
    -- dos relojes se separan: sin este margen, la gravedad podria empezar a
    -- caer el fotograma justo antes de que llegue el ultimo trozo.
    return retardo > 0 and retardo + 0.04 or 0
end

-- Los rotulos de cascada. Solo a partir de la tercera: felicitar al jugador
-- por lo que hace cada movimiento no es felicitar, es ruido.
-- La cuenta pendiente del arcade: lo que lleva la cascada hasta ahora. El
-- Mult que se ensena es el de la jugada del dedo y no se mueve mientras cae
-- nada (la cascada solo suma Base); lo que dependa de la cascada misma
-- (Cadena, Remanso) sale luego, en la secuencia.
local function actualizarPendiente()
    if not (run and enCurso and enCurso.forma) then return end
    local pv = Puntuacion.calcular(enCurso, puntEstado, puntMods, true)
    Pizarra.pendiente(pv.nombre, pv.nivel, pv.base, pv.mult * pv.xmult, pv.clave == "combo")
end

local ROTULOS = { [3] = "¡Woof!", [4] = "¡Canino!", [5] = "¡Que aproveche!", [6] = "¡Dale Kiko!" }

local function animarSuceso(suceso, cascada)
    for k, onda in ipairs(suceso.ondas) do
        local retardo = animarOnda(onda, cascada + k - 1)
        apuntarRotas(onda)
        -- El `retardo` es lo que tardan las estrellas en llegar. Hay que
        -- esperarlo tambien en la ULTIMA onda: si no, la gravedad empieza a
        -- caer sobre casillas que todavia se ven llenas y las galletas se
        -- cruzan con las estrellas que van a por ellas.
        if k < #suceso.ondas then
            esperarTweens(T_ONDA + retardo)
        elseif retardo > 0 then
            esperarTweens(retardo)
        end
    end

    cascadaMaxima = math.max(cascadaMaxima, cascada)
    local primera = suceso.ondas[1].celdas[1]

    if run then
        -- En el arcade el total NO se toca aqui: el movimiento se cobra entero
        -- cuando acaba la cascada (`cobrar`). Lo que sube desde la jugada es la
        -- BASE que acaba de sumar, sin multiplicador -- la cascada suma Base y
        -- no Mult, y el numero lo dice.
        enCurso = enCurso or Puntuacion.nuevaJugada()
        local antes = Puntuacion.base(enCurso, puntMods)
        Puntuacion.sumarSuceso(enCurso, suceso)
        local gana = Puntuacion.base(enCurso, puntMods) - antes
        actualizarPendiente()
        if primera and gana > 0 then
            local x, y = centro(primera.i)
            Efectos.numero(x * Constants.ART, y * Constants.ART, gana,
                           cascada > 1 and Palette.gold or Palette.text)
        end
    else
        progreso.puntos = progreso.puntos + suceso.puntos

        -- El marcador de la cabecera no salta al total nuevo: RUEDA hasta el,
        -- con su achuchon y sus clics. Se le pasa el eslabon de la cadena
        -- porque en un combo lo que hay que ver crecer no es cada cobro por
        -- separado, es que la cuenta no llega a pararse entre uno y el
        -- siguiente.
        Efectos.contar(progreso.puntos, cascada)

        -- El numero sube desde donde ha pasado la cosa, no desde el marcador:
        -- es lo que ata los puntos a la jugada que los ha dado. Y lleva al lado
        -- el multiplicador con el que se han cobrado -- el del tablero, no uno
        -- inventado aqui: es lo unico de una cadena que no se ve mirandola.
        if primera then
            local x, y = centro(primera.i)
            Efectos.numero(x * Constants.ART, y * Constants.ART, suceso.puntos,
                           cascada > 1 and Palette.gold or Palette.text,
                           suceso.multiplicador)
        end
    end

    if ROTULOS[math.min(cascada, 6)] and cascada >= 3 then
        Efectos.rotulo(ROTULOS[math.min(cascada, 6)])
    elseif (suceso.bonusColor or 0) > 0 then
        -- La racha de color, dicha con el NOMBRE de la galleta y su color: es
        -- un premio que depende de la jugada anterior, y sin verlo escrito no
        -- hay forma de saber que existe -- los puntos suben igual que siempre.
        -- Solo cuando de verdad ha cobrado algo (`bonusColor`), que es lo mismo
        -- que decir "solo en el arcade y solo con la mejora cogida": la
        -- pantalla no pregunta por la mejora, pregunta por los puntos.
        --
        -- Y cede el sitio al rotulo de la cascada, que solo sale a partir de la
        -- tercera y es el momento mas gordo de los dos. Los rotulos son de uno
        -- en uno (`Efectos.rotulo` tira el anterior), asi que aqui hay que
        -- elegir: dos seguidos parpadearian y no se leeria ninguno.
        --
        -- El `x` es el de la racha COBRADA y no el de la de verdad: pasado el
        -- tope deja de subir, igual que dejan de subir los puntos. Decir x7
        -- cobrando cuatro seria ensenar un numero que no esta en ningun sitio.
        local fam = suceso.colorRacha and Palette.galletas[suceso.colorRacha]
        if fam then
            -- La inicial a mano y no con `upper()` entero: "limón" lleva una
            -- letra de dos bytes y `string.upper` la dejaria en "LIMóN".
            local nombre = fam.nombre:sub(1, 1):upper() .. fam.nombre:sub(2)
            Efectos.rotulo(string.format("¡%s x%d!", nombre, suceso.eslabones + 1),
                           colorDe(suceso.colorRacha))
        end
    end

    -- Las especiales que nacen no aparecen: CRECEN de golpe desde la nada, con
    -- rebote. Es el unico premio del juego y tiene que verse llegar.
    refrescar()
    for _, nueva in ipairs(suceso.creadas) do
        local p = piezas[nueva.id]
        if p then
            p.ex, p.ey = 0.2, 0.2
            flux.to(p, 0.28, { ex = 1, ey = 1 }):ease("backout")
            local x, y = centro(nueva.i)
            Efectos.onda(x, y, T * 1.2, colorDe(nueva.color))
            Sfx.play("toque", 1.5)
        end
    end
end

-- Todo lo que cae, de una vez. Devuelve lo que tarda la caida mas larga, que
-- es lo que hay que esperar antes de volver a mirar el tablero.
local function animarCaida(caida)
    local masLarga = 0

    local function aterriza(p, destinoY, distancia)
        local dur = math.max(T_MIN, distancia * T_CAIDA)
        masLarga = math.max(masLarga, dur)
        -- Cae acelerando y al llegar se APLASTA y se recompone. El aplastado
        -- dura 0,09 s y es la diferencia entre galletas que se posan y galletas
        -- que tienen peso; sin el, una columna entera cayendo se ve como una
        -- lista que hace scroll.
        flux.to(p, dur, { y = destinoY }):ease("quadin"):oncomplete(function()
            p.ex, p.ey = 1.22, 0.76
            flux.to(p, 0.16, { ex = 1, ey = 1 }):ease("backout")
            Sfx.play("toque", 0.85 + love.math.random() * 0.3, 0.5)
        end)
    end

    -- Las pastillas que se recogen en ESTA misma pasada no aterrizan: siguen
    -- de largo hasta salirse del lienzo (mas abajo). Hay que saberlo ANTES de
    -- animar los movimientos, porque flux solo deja viva la ULTIMA animacion
    -- que arranca sobre la misma propiedad, y arranca por orden inverso: el
    -- aterrizaje, que se pide primero, le ganaba a la salida del bol y dejaba
    -- la pastilla clavada en la ultima casilla, debajo de la galleta que caia
    -- encima.
    local seRecoge = {}
    for _, k in ipairs(caida.recogidos) do seRecoge[k.id] = true end

    for _, m in ipairs(caida.movimientos) do
        local p = piezas[m.id]
        if p then
            local x, y = centro(m.a)
            local distancia = math.abs(y - p.y) / T
            p.x = x
            if not seRecoge[m.id] then aterriza(p, y, distancia) end
        end
    end

    for _, a in ipairs(caida.apariciones) do
        local celda = board.celdas[a.a]
        if celda then
            local x, y = centro(a.a)
            -- Nace POR ENCIMA del tablero, a la altura que le toca en la cola
            -- de su columna: asi una columna vacia se rellena como una cascada
            -- y no como una fila que aparece de golpe.
            local p = crearPieza(celda, a.a, y - a.altura * T - T)
            p.x = x
            aterriza(p, y, (y - p.y) / T)
        end
    end

    for _, k in ipairs(caida.recogidos) do
        local p = piezas[k.id]
        local x, y = centro(k.i)
        if p then
            piezas[k.id] = nil
            moribundas[#moribundas + 1] = p
            -- La pastilla no revienta y tampoco se queda en la ultima fila: se
            -- CAE DEL BOL y se va por debajo del lienzo, que es lo que cuenta
            -- el objetivo ("dale una pastilla a Kiko"). Antes se paraba dos
            -- casillas mas abajo y se quedaba ahi hasta el final del nivel,
            -- encima del faldon, como una pastilla olvidada.
            --
            -- Sale ACELERANDO y sin encoger: encoger mientras cae se lee como
            -- que se desvanece, y lo que tiene que leerse es que se va.
            local destino = Constants.ART_H + T * 2
            local dur = math.max(0.30, (destino - p.y) / T * 0.045)
            flux.to(p, dur, { y = destino }):ease("quadin")
        end
        particulas:confeti(x, y, 16)
        Efectos.numero(x * Constants.ART, y * Constants.ART,
                       run and Puntuacion.C.PASTILLA or Board.PUNTOS.pastilla, Palette.gold)
        Efectos.temblar(2)
        Sfx.play("campana", 1.2)
        Sfx.vibrar(0.05)
    end

    if run then
        -- En el arcade la pastilla es Base del movimiento en curso.
        if #caida.recogidos > 0 then
            enCurso = enCurso or Puntuacion.nuevaJugada()
            Puntuacion.sumarPastillas(enCurso, #caida.recogidos)
            actualizarPendiente()
        end
    else
        progreso.puntos = progreso.puntos + (caida.puntos or 0)
        -- Dos mil puntos de una pastilla son el cobro mas gordo del juego, y
        -- por eso es el que mas rueda: la cuenta sale sola de lo que se ha
        -- ganado (ver `Efectos.contar`) sin que aqui haya que pedir nada
        -- especial.
        if (caida.puntos or 0) > 0 then Efectos.contar(progreso.puntos, 1) end
    end
    progreso.pastillas = board.pastillasRecogidas
    return masLarga
end

--== La cascada ============================================================

local function actualizarProgreso()
    progreso.barro = board:barroVivo()
    progreso.hielo = board:hieloVivo()
    progreso.moho = board:mohoVivo()
    progreso.pastillas = board.pastillasRecogidas
end

-- Cae todo lo que tenga que caer, tantas pasadas como haga falta.
local function asentar()
    local vueltas = 0
    while vueltas < 40 do
        vueltas = vueltas + 1
        local caida = board:gravedad()
        if not caida then break end
        local dur = animarCaida(caida)
        Director.esperar(dur + T_POSO)
    end
end

-- El bucle entero: resolver, animar, dejar caer, volver a mirar. `preferidas`
-- son las casillas del intercambio que lo ha empezado (nil en una cascada).
local function resolverTodo(preferidas)
    local cascada = 1
    while true do
        local suceso = board:resolver(preferidas, cascada)
        if not suceso then break end
        preferidas = nil
        animarSuceso(suceso, cascada)
        actualizarProgreso()
        Director.esperar(T_POP)
        asentar()
        cascada = cascada + 1
    end
end

-- Cobra el movimiento del arcade: Base x Mult de todo lo que ha pasado desde
-- que el dedo solto, una vez y con el tablero ya quieto. Lo que devuelve la
-- cuenta trae tambien el estado siguiente (escalada, afinidad), que es el que
-- vera el movimiento que viene. En la campana no hace nada.
--
-- La cuenta se ENSENA antes de sumarse (`src/pizarra.lua`): forma, Base, Mult
-- y cada bonus uno a uno, y el total vuela a la cabecera. El director espera a
-- que acabe -- el tablero no admite otro movimiento mientras tanto, y un toque
-- la acelera o la salta -- y solo entonces suma el total y mira si la ronda
-- se ha ganado.
local function cobrar()
    if not (run and enCurso) then return end
    local jugada = enCurso
    enCurso = nil
    if not jugada.forma and Puntuacion.base(jugada, puntMods) <= 0 then return end
    local r = Puntuacion.calcular(jugada, puntEstado, puntMods)
    puntEstado = r.estado
    Pizarra.secuencia(r)
    Director.hasta(Pizarra.libre)
    progreso.puntos = progreso.puntos + r.total
    -- El calor del marcador sale de cuantos bonus se han sumado: una jugada
    -- con escalada, afinidad y una rara se enciende como una cadena larga.
    Efectos.contar(progreso.puntos, math.min(6, 1 + #r.pasosMult + #r.pasosX))
end

-- Sin jugadas posibles no se puede seguir: se barajan los colores delante del
-- jugador. Se ve, y se ve que es el juego quien lo hace: un tablero que cambia
-- solo sin avisar se lee como un fallo.
local function barajarSiHaceFalta()
    while not board:hayJugada() do
        local suceso = board:barajar()
        if not suceso then break end   -- no hay barajado posible: se deja estar

        Efectos.rotulo("Sin jugadas", Palette.red)
        Sfx.play("pelota", 0.7)
        -- Cada galleta se da la vuelta (se estrecha hasta desaparecer, cambia
        -- de color y vuelve), escalonada por filas: el barrido dice que ha
        -- pasado por TODAS, que es lo que hay que entender.
        for _, cambio in ipairs(suceso.cambios) do
            local p = piezas[cambio.id]
            if p then
                local c, r = board:cr(cambio.i)
                local retardo = (c + r) * 0.02
                flux.to(p, 0.16, { ex = 0 }):delay(retardo):ease("quadin")
                    :oncomplete(function()
                        p.color = board.celdas[cambio.i] and board.celdas[cambio.i].color
                        Sfx.play("toque", 1.2, 0.35)
                    end)
                    :after(p, 0.16, { ex = 1 }):ease("quadout")
            end
        end
        Director.esperar(0.75)
        refrescar()
        resolverTodo(nil)
    end
end

-- El moho crece al final de la jugada.
--
-- La regla entera es del tablero (`Board:crecerMoho`: cada cuantas jugadas,
-- donde puede prender y que se apaga al llegar a cero); lo unico que se pone
-- aqui es el MOMENTO y el aviso, igual que con `resolver` o `gravedad`.
--
-- Y el aviso no es un adorno: el brote es lo unico de este tablero que se
-- mueve sin que el jugador haya tocado nada, y un bol que cambia solo y en
-- silencio no se lee como un estorbo que avanza -- se lee como un fallo. Las
-- migas y la nota grave son lo que lo convierten en algo que ha PASADO.
--
-- No crece en la jugada que gana: un brote en el mismo fotograma que el cartel
-- es una mancha que ya no se puede limpiar, y lo unico que cuenta es que el
-- juego siguio jugando despues de acabar.
local function brotarMoho()
    if objetivoCumplido() then return end
    local brote = board:crecerMoho()
    if not brote then return end
    actualizarProgreso()
    local x, y = centro(brote.i)
    particulas:estallido(x, y, 7, Palette.moho, 0.8)
    Sfx.play("toque", 0.55, 0.6)
    Director.esperar(0.12)
end

--== Final del nivel =======================================================

-- El remate: los movimientos que sobran se convierten en rayadas y estallan
-- uno detras de otro. Es la unica parte del juego en la que el jugador no
-- hace nada, y esta ahi porque ganar tiene que durar algo mas que un cartel:
-- son los puntos que le sobraban, cobrados delante de el.
local function remate()
    local restantes = math.min(movimientos, 10)
    if restantes <= 0 then return end

    Efectos.rotulo("¡Galleta loca!", Palette.gold)
    for k = 1, restantes do
        -- Una galleta normal cualquiera, y se vuelve rayada. Si no queda
        -- ninguna (tablero de especiales) se deja de rematar.
        local candidatas = {}
        for i = 1, board.cols * board.rows do
            local celda = board.celdas[i]
            -- Una rayada dentro de un cubito no dispara: seria un movimiento
            -- del remate tirado a la basura, y el remate es justo lo que cobra
            -- los que sobraban.
            if celda and celda.color and not celda.especial and not celda.hielo then
                candidatas[#candidatas + 1] = i
            end
        end
        if #candidatas == 0 then break end

        local i = candidatas[love.math.random(#candidatas)]
        board.celdas[i].especial = (k % 2 == 0) and "rayaH" or "rayaV"
        refrescar()
        local p = piezas[board.celdas[i].id]
        if p then
            p.ex, p.ey = 0.3, 0.3
            flux.to(p, 0.18, { ex = 1, ey = 1 }):ease("backout")
        end
        movimientos = movimientos - 1
        Director.esperar(0.10)

        local suceso = board:detonar(i, 1)
        if suceso then
            animarSuceso(suceso, 1)
            actualizarProgreso()
            Director.esperar(T_ONDA)
            asentar()
        end
    end
end

local function terminar(gano)
    estado = gano and "ganado" or "perdido"

    -- El cartel del final dice el total, y aparece de golpe. Si el marcador
    -- se quedara rodando por detras, la cabecera y el cartel dirian dos cifras
    -- distintas en la misma pantalla: la cuenta se acaba aqui.
    Efectos.marcador(progreso.puntos)

    -- El arcade no apunta estrellas ni nivel pasado: lo que guarda es hasta
    -- donde llego la PARTIDA, y eso solo se sabe cuando se pierde. Una ronda
    -- ganada suma sus puntos al bote y saca las tres cartas.
    if run then
        if gano then
            Arcade.rondaGanada(run, progreso.puntos)
            Sfx.play("campana", 1.2)
            Sfx.play("campana", 1.6)
            particulas:confeti(board.cols * T / 2 + ox, oy + board.rows * T / 2, 60)
        else
            Session.apuntarArcade(run.ronda, run.puntos + progreso.puntos)
            Sfx.play("nada", 0.8)
        end
        return
    end

    if gano then
        -- Las estrellas son PUNTOS y nada mas. Pasar un nivel no regala
        -- ninguna: si aqui se forzara un minimo de una, la barra de la
        -- cabecera (que las pinta por puntos) diria una cosa y el cartel otra,
        -- delante del jugador y en la misma pantalla.
        local estrellas = Levels.estrellas(def, progreso.puntos)
        Juego.estrellasGanadas = estrellas
        Session.apuntar(numero, true, estrellas, progreso.puntos)
        for k = 1, math.max(1, estrellas) do
            Sfx.play("campana", 1 + k * 0.25)
        end
        particulas:confeti(board.cols * T / 2 + ox, oy + board.rows * T / 2, 90)
    else
        -- Perder tambien apunta: los puntos y las estrellas que se hayan sacado
        -- son suyos aunque el barro se quedara a medias.
        Juego.estrellasGanadas = Levels.estrellas(def, progreso.puntos)
        Session.apuntar(numero, false, Juego.estrellasGanadas, progreso.puntos)
        Sfx.play("nada", 0.8)
    end
end

-- Se llama al final de cada jugada.
--
-- Un nivel de OBJETIVO (barro, pastillas, recoger) se gana en cuanto el
-- objetivo esta hecho, queden los movimientos que queden -- y entonces viene
-- el remate, que cobra los que sobraban.
--
-- Un nivel de PUNTOS no se corta en la meta: la meta es la PRIMERA estrella y
-- acabar ahi dejaria las otras dos sin ensenar a nadie. Se corta en la de
-- ARRIBA, que es otra cosa: pasado el tercer umbral ya no queda estrella que
-- esconder, y lo que queda de nivel es sumar a un marcador que ya no cambia
-- nada. Ahi el remate cobra los movimientos que sobraban, igual que en los
-- otros -- que es justo el sitio donde antes no llegaba nunca.
local function comprobarFinal()
    -- Una ronda de arcade se CORTA al llegar a la meta, aunque su objetivo sea
    -- de puntos. En la campana la meta no corta -- es la primera estrella, y
    -- acabar ahi esconderia las otras dos; alli se corta en la de arriba,
    -- cuando ya no queda ninguna que esconder. Aqui no hay estrellas y la meta
    -- ES el final: lo que hay despues no son mas puntos, es la mejora
    -- siguiente.
    --
    -- Tampoco hay remate: los movimientos que sobran no se cobran porque no
    -- hay nada que cobrar, la ronda ya esta ganada. Lo que se lleva el jugador
    -- de haberla pasado con movimientos de sobra es que la siguiente empieza
    -- antes.
    if run then
        if objetivoCumplido() then terminar(true) return end
        if movimientos <= 0 then terminar(false) end
        return
    end

    -- El techo de un nivel de puntos es su umbral mas alto, no su meta. En un
    -- nivel de objetivo no hay techo ninguno: se gana al cumplirlo.
    local techo = def.objetivo.tipo == "puntos"
        and def.estrellas[#def.estrellas] or 0

    if objetivoCumplido() and progreso.puntos >= techo then
        remate()
        terminar(true)
        return
    end

    if movimientos <= 0 then
        if objetivoCumplido() then
            terminar(true)
        else
            terminar(false)
        end
    end
end

--== El dedo ===============================================================

local function celdaEn(vx, vy)
    local ax, ay = vx / Constants.ART, vy / Constants.ART
    local c = math.floor((ax - ox) / T) + 1
    local r = math.floor((ay - oy) / T) + 1
    local i = board:idx(c, r)
    if i and board.mascara[i] and board.celdas[i] then return i end
    return nil
end

local function intentar(i, j)
    if estado ~= "jugando" or Director.ocupado() then return end
    if not board:adyacentes(i, j) then return end
    local celdaI, celdaJ = board.celdas[i], board.celdas[j]
    if not (celdaI and celdaJ) then return end

    if celdaI.hielo or celdaJ.hielo then
        seleccion, pista, ocioso = nil, nil, 0
        tiritar(piezas[celdaI.hielo and celdaI.id or celdaJ.id])
        return
    end

    seleccion, pista, ocioso = nil, nil, 0
    local tipo = board:jugada(i, j)
    local pi, pj = piezas[celdaI.id], piezas[celdaJ.id]
    if not (pi and pj) then return end

    local xi, yi = centro(i)
    local xj, yj = centro(j)

    Director.lanzar(function()
        Sfx.play("mover")
        flux.to(pi, T_SWAP, { x = xj, y = yj }):ease("quadout")
        flux.to(pj, T_SWAP, { x = xi, y = yi }):ease("quadout")
        Director.esperar(T_SWAP)

        if not tipo then
            -- No valia: vuelven a su sitio. Es importante que se VEAN volver
            -- (y no que no se muevan): el jugador tiene que ver que el juego
            -- ha entendido el gesto y que la jugada es la que no vale.
            Sfx.play("nada")
            Efectos.temblar(0.8)
            flux.to(pi, T_VUELTA, { x = xi, y = yi }):ease("quadout")
            flux.to(pj, T_VUELTA, { x = xj, y = yj }):ease("quadout")
            Director.esperar(T_VUELTA)
            return
        end

        movimientos = movimientos - 1
        -- Se ha casado algo: el perro se despierta. Aqui y no en `press`, que
        -- es lo que hace que el bostezo cuente jugadas y no toques.
        sinJugada = 0
        if run then enCurso = Puntuacion.nuevaJugada() end
        board:intercambiar(i, j)

        if tipo == "combo" then
            local suceso = board:combo(j, i, 1)
            if suceso then
                animarSuceso(suceso, 1)
                actualizarProgreso()
                Director.esperar(T_POP)
                asentar()
            end
            resolverTodo(nil)
        else
            resolverTodo({ j, i })
        end
        cobrar()

        brotarMoho()
        barajarSiHaceFalta()
        cobrar()
        comprobarFinal()
    end)
end

-- Lo que daria intercambiar i y j, en la pizarra y sin tocar el tablero. Sin
-- cascada, que no se puede saber: es forma y "Base x Mult" de la jugada del
-- dedo con la escalada y la afinidad que llevaria.
function previsualizar(i, j)
    if not j then Pizarra.previa(nil) return end
    local tipo = board:jugada(i, j)
    if not tipo then Pizarra.previa({ invalida = true }) return end
    if tipo == "combo" then
        -- `a` es la que mueve el dedo; el color sale igual que en `Board:combo`.
        local a, b = board.celdas[i], board.celdas[j]
        local color
        if a.especial == "pelota" and b.especial == "pelota" then color = nil
        elseif a.especial == "pelota" then color = b.color
        elseif b.especial == "pelota" then color = a.color
        else color = a.color or b.color end
        Pizarra.previa(Puntuacion.preverCombo(a.especial, b.especial, color, puntEstado, puntMods))
    else
        Pizarra.previa(Puntuacion.prever(board:gruposDeIntercambio(i, j), puntEstado, puntMods))
    end
end

function Juego.press(x, y)
    -- Con la cuenta de un movimiento en pantalla, un toque la acelera y el
    -- segundo la salta. Va antes que todo lo demas: mientras se ensena la
    -- cuenta el tablero esta ocupado, y ese toque no puede ser otra cosa.
    if not confirmar and Pizarra.enSecuencia() then
        Pizarra.saltar()
        return
    end
    -- Con la pregunta delante el tablero no admite dedos, por lo mismo que no
    -- los admite a media cascada: lo que se ve debajo del velo no es lo que se
    -- esta tocando.
    if estado ~= "jugando" or confirmar or Director.ocupado() then return end
    local i = celdaEn(x, y)
    arrastre = i and { i = i, x = x, y = y } or nil
    if not i then return end

    if board:congelada(i) then
        -- Tocar un cubito no lo elige: lo hace temblar. Dejarlo elegido seria
        -- dejar encendida una casilla desde la que no sale ninguna jugada.
        arrastre, seleccion = nil, nil
        tiritar(piezas[board.celdas[i].id])
        ocioso, pista = 0, nil
        return
    end

    if seleccion == i then
        -- Volver a tocar la elegida la suelta. Sin esto, la unica forma de
        -- deshacer una eleccion es tocar otra galleta, y eso deja al jugador
        -- con una casilla encendida que no queria.
        seleccion = nil
    elseif seleccion and board:adyacentes(seleccion, i) then
        intentar(seleccion, i)
    else
        seleccion = i
    end
    ocioso, pista = 0, nil
end

-- El arrastre: en cuanto el dedo sale de la casilla por un lado, esa es la
-- jugada. No hace falta soltar dentro de la casilla de destino -- en un movil,
-- soltar donde tapa el dedo es pedirle punteria a quien juega de pie.
--
-- En el ARCADE no: el arrastre apunta y el soltar confirma, porque entre
-- medias la pizarra ensena lo que daria la jugada (forma y "Base x Mult", sin
-- la cascada). Volver el dedo a su casilla la cancela. La campana sigue
-- jugando al pasar el umbral, como siempre.
function Juego.move(x, y)
    if not arrastre or estado ~= "jugando" or confirmar or Director.ocupado() then return end
    local dx, dy = x - arrastre.x, y - arrastre.y
    local umbral = T * Constants.ART * 0.5
    if math.abs(dx) < umbral and math.abs(dy) < umbral then
        if run and arrastre.destino then
            arrastre.destino = nil
            Pizarra.previa(nil)
        end
        return
    end

    if run then
        local c, r = board:cr(arrastre.i)
        if math.abs(dx) > math.abs(dy) then c = c + (dx > 0 and 1 or -1)
        else r = r + (dy > 0 and 1 or -1) end
        local destino = board:idx(c, r)
        if destino and not (board.mascara[destino] and board.celdas[destino]) then destino = nil end
        if destino ~= arrastre.destino then
            arrastre.destino = destino
            previsualizar(arrastre.i, destino)
        end
        return
    end

    local c, r = board:cr(arrastre.i)
    if math.abs(dx) > math.abs(dy) then
        c = c + (dx > 0 and 1 or -1)
    else
        r = r + (dy > 0 and 1 or -1)
    end
    local destino = board:idx(c, r)
    local origen = arrastre.i
    arrastre = nil
    if destino and board.mascara[destino] and board.celdas[destino] then
        intentar(origen, destino)
    end
end

function Juego.release()
    local a = arrastre
    arrastre = nil
    if run then Pizarra.previa(nil) end
    if run and a and a.destino and estado == "jugando" and not confirmar
       and not Director.ocupado() then
        intentar(a.i, a.destino)
    end
end

function Juego.keypressed(key)
    -- `appback` es el boton de atras del telefono -- y el gesto del sistema que
    -- lo sustituye --; `escape` es lo mismo en escritorio. Ninguno de los dos
    -- se va ya del nivel: levantan la pregunta, y si la pregunta ya esta
    -- puesta la quitan, porque atras sobre una pregunta es que no.
    if key == "escape" or key == "appback" then
        if confirmar then
            confirmar = false
        else
            pedirSalir()
        end
    elseif key == "r" and not run and not confirmar then
        -- Reiniciar es de la campana. En el arcade seria repetir la ronda con
        -- otro reparto hasta que salga una buena, que es exactamente lo que no
        -- es una partida.
        Juego.enter(numero)
    end
end

--== Ciclo =================================================================

-- `partida` es la del arcade (`src/arcade.lua`). Con ella, `n` se ignora: la
-- ronda que toca la dice la partida.
function Juego.enter(n, partida)
    run = partida
    if run then
        numero = run.ronda
        def = Arcade.nivel(run)
    else
        numero = n or 1
        def = Levels.get(numero)
    end
    Director.cortar()
    flux.tweens = {}
    Efectos.reset()

    board = Board.nuevo({
        cols = Constants.COLS, rows = Constants.ROWS,
        colores = def.colores,
        semilla = os.time() * 1000 + numero,
        mascara = Levels.mascara(def),
        barro = Levels.barro(def),
        hielo = Levels.hielo(def),
        moho = Levels.moho(def),
        pastillas = def.pastillas or 0,
        pastillasALaVez = def.pastillasALaVez,
        -- Las mejoras del arcade. El tablero copia las que conoce y se olvida
        -- del resto (los movimientos son del arcade y no suyos), asi que esto
        -- puede ir tal cual.
        mods = run and Arcade.mods(run) or nil,
    })

    piezas, moribundas = {}, {}
    particulas = Particles.nuevo()
    progreso = { puntos = 0, barro = board:barroVivo(), hielo = board:hieloVivo(),
                 moho = board:mohoVivo(), pastillas = 0, recogidos = {} }
    movimientos = def.movimientos
    estado = "jugando"
    -- La escalada y la afinidad empiezan en cero en cada ronda.
    puntEstado = run and Puntuacion.nuevoEstado() or nil
    puntMods = run and Arcade.mods(run) or nil
    enCurso = nil
    Pizarra.reset()
    seleccion, arrastre, ocioso, pista = nil, nil, 0, nil
    -- Lo que hay que limpiar al empezar. Se apunta ahora porque luego ya no se
    -- puede saber: a media partida solo queda lo que queda, y sin el total de
    -- salida no hay forma de decir si eso es mucho o casi nada.
    inicial = { barro = progreso.barro, hielo = progreso.hielo, moho = progreso.moho }
    sinJugada = 0
    kiko = Kiko.nuevo()
    confirmar, dudoso = false, Kiko.nuevo("duda")
    cascadaMaxima = 1
    Juego.estrellasGanadas = 0

    Juego.resize()

    -- El tablero entra cayendo del cielo, escalonado por filas. Dura poco mas
    -- de medio segundo y es lo que hace que empezar un nivel sea empezar algo
    -- en vez de encontrarse una pantalla ya puesta.
    for i = 1, board.cols * board.rows do
        local celda = board.celdas[i]
        if celda then
            local x, y = centro(i)
            local c, r = board:cr(i)
            local p = crearPieza(celda, i, y - (board.rows + 4) * T)
            flux.to(p, 0.45 + r * 0.03, { y = y })
                :delay(c * 0.02):ease("quadin")
                :oncomplete(function()
                    p.ex, p.ey = 1.18, 0.8
                    flux.to(p, 0.14, { ex = 1, ey = 1 }):ease("backout")
                    -- El mismo toque que cualquier otra caida: el escalonado
                    -- por filas y columnas lo convierte en el redoble de una
                    -- cascada, y sin el la entrada se ve caer pero no se oye.
                    Sfx.play("toque", 0.85 + love.math.random() * 0.3, 0.5)
                end)
        end
    end
end

function Juego.leave()
    Director.cortar()
end

function Juego.resize()
    ox, oy = Constants.boardOrigin()

    -- El faldon solo existe si cabe. En un lienzo corto (escritorio apaisado)
    -- lo que hay debajo del tablero es el boton de salir, y un bol que llega
    -- hasta el boton no se lee como un bol mas largo: se lee como que el
    -- boton esta dentro del bol. Sin sitio, el nombre no se dibuja y ya esta.
    local libre = (Constants.ART_H - math.floor(Constants.SAFE_BOTTOM / Constants.ART))
                  - (oy + board.rows * T + 4)
    faldon = libre >= FALDON + 8 and FALDON or 0

    for i = 1, board.cols * board.rows do
        local celda = board.celdas[i]
        if celda and piezas[celda.id] then
            local p = piezas[celda.id]
            p.x, p.y = centro(i)
        end
    end
end

function Juego.update(dt)
    -- flux NO se actualiza aqui: lo hace main.lua, una sola vez por fotograma
    -- y para todo el juego. Actualizarlo en los dos sitios hace que cada tween
    -- corra al doble de velocidad, que es un fallo que se ve como "las
    -- animaciones van raras" y no como lo que es.
    Director.update(dt)
    Efectos.update(dt)
    Pizarra.update(dt)
    particulas:update(dt)

    -- El perro. El animo se le dice ENTERO cada fotograma en vez de avisarle
    -- en los sitios donde cambia algo: lo que pone una cara no es un suceso
    -- (no hay un momento en que el jugador "se acerque al objetivo"), es como
    -- esta la partida ahora mismo. Pedir el animo que ya tiene no le cuesta
    -- nada ni le reinicia la cara (ver `Perro:pon`).
    sinJugada = sinJugada + dt
    kiko:pon(animoDeKiko())
    kiko:update(dt)
    -- El de la pregunta solo corre mientras se ve. Hoy `duda` es una sola cara
    -- y esto no mueve nada; el dia que sean dos, se mueve solo.
    if confirmar then dudoso:update(dt) end

    for k = #moribundas, 1, -1 do
        local p = moribundas[k]
        -- Se tira lo que ya no se ve: lo que ha encogido hasta nada (una
        -- galleta reventada) y lo que ha salido por debajo del lienzo (una
        -- pastilla que se ha caido del bol). El corte va contra ART_H y no
        -- contra la ultima fila del tablero: entre el tablero y el canto de
        -- abajo estan el faldon y el boton, y ahi la pastilla todavia se ve.
        if p.ex <= 0.02 or p.y > Constants.ART_H + T then
            table.remove(moribundas, k)
        end
    end

    -- La pista: si el jugador lleva un rato sin tocar, se le ensena UNA jugada.
    -- Solo cuando el tablero esta quieto -- una pista durante una cascada
    -- senala una casilla que va a cambiar -- y se apaga en cuanto toca.
    if estado == "jugando" and not Director.ocupado() then
        ocioso = ocioso + dt
        if ocioso > OCIO_PISTA and not pista then
            local i, j = board:hayJugada()
            if i then pista = { i = i, j = j, t = 0 } end
        end
    end
    if pista then pista.t = pista.t + dt end
end

--== Dibujo ================================================================

-- Un rectangulo de un color, en pixeles de arte y enteros. El marco son diez
-- de estos y escribirlos a mano es diez veces `setColor` + `rectangle`.
local function barra(c, x, y, w, h)
    love.graphics.setColor(c)
    love.graphics.rectangle("fill", x, y, w, h)
end

local function dibujarTablero()
    -- El BOL: un cuenco de acero alrededor del tablero. No es adorno -- sin
    -- el, el tablero flota en mitad de la pantalla y el hueco que queda entre
    -- la cabecera y la primera fila se lee como que falta algo. Con bol, ese
    -- hueco es la encimera.
    --
    -- Que parezca metal y no un marco gris es cosa de tres decisiones: la luz
    -- cae SIEMPRE arriba a la izquierda (el canto de arriba y el de la
    -- izquierda son claros, los de abajo y la derecha oscuros), el borde de
    -- dentro va oscuro para que el bol tenga hondura, y el brillo especular
    -- son dos segmentos CORTOS en el canto de arriba -- no una linea entera.
    -- Un reflejo que recorre todo el canto se lee como un bisel de ventana;
    -- uno corto e interrumpido se lee como acero pulido.
    --
    -- El acero baja MAS ABAJO que el tablero: esa franja de sobra es el
    -- faldon, y es donde va grabado el nombre. Un bol con el nombre del perro
    -- es lo que convierte el marco en un objeto de alguien; ademas le da pie
    -- al tablero, que apoyado solo en su propio canto parecia flotar.
    local w, h = board.cols * T, board.rows * T
    local alto = h + 8 + faldon                                -- todo el acero
    barra(Palette.ink,       ox - 5, oy - 5, w + 10, alto + 3) -- canto exterior
    barra(Palette.metal,     ox - 4, oy - 4, w + 8,  alto)     -- cuerpo del acero
    barra(Palette.metalLite, ox - 4, oy - 4, w + 8,  1)        -- luz arriba
    barra(Palette.metalLite, ox - 4, oy - 4, 1,      alto)     -- luz izquierda
    barra(Palette.metalDark, ox - 4, oy - 4 + alto - 1, w + 8, 1)  -- sombra abajo
    barra(Palette.metalDark, ox + w + 3, oy - 4, 1,  alto)     -- sombra derecha
    barra(Palette.metalShine, ox + math.floor(w * 0.20), oy - 4, math.floor(w * 0.09), 1)
    barra(Palette.metalShine, ox + math.floor(w * 0.36), oy - 4, math.floor(w * 0.03), 1)
    barra(Palette.metalShine, ox - 4, oy + math.floor(h * 0.12), 1, math.floor(h * 0.07))
    if faldon > 0 then
        -- El reborde: donde acaba el cuenco y empieza el faldon, una linea
        -- oscura con otra clara debajo. Son dos pixeles y son los que hacen
        -- que el faldon sea OTRO plano y no mas marco; sin ellos, el bol
        -- parece simplemente un marco demasiado gordo por abajo.
        barra(Palette.metalDark, ox - 4, oy + h + 4, w + 8, 1)
        barra(Palette.metalLite, ox - 4, oy + h + 5, w + 8, 1)
    end
    barra(Palette.metalDark, ox - 2, oy - 2, w + 4, h + 4)     -- la pared cae
    -- El fondo del bol se ve solo por las juntas entre casillas y por los
    -- agujeros del nivel, y va en acero oscuro y NO en tinta: en tinta, esas
    -- juntas se leen como una rejilla negra dibujada encima del metal, que es
    -- justo lo que el damero esta puesto para evitar.
    barra(Palette.metalDark, ox - 1, oy - 1, w + 2, h + 2)
    love.graphics.setColor(1, 1, 1, 1)

    -- El damero: dos tonos alternos. Se dibuja casilla a casilla y no como un
    -- rectangulo grande porque los niveles tienen forma -- hay agujeros -- y
    -- el borde del tablero es justo lo que dice cual es la forma.
    for i = 1, board.cols * board.rows do
        if board.mascara[i] then
            local c, r = board:cr(i)
            local x, y = ox + (c - 1) * T, oy + (r - 1) * T
            Art.draw((c + r) % 2 == 0 and "casilla" or "casillaAlt", x, y)
        end
    end

    for i = 1, board.cols * board.rows do
        local capas = board.barro[i] or 0
        if capas > 0 then
            local c, r = board:cr(i)
            Art.draw(capas >= 2 and "barro2" or "barro1", ox + (c - 1) * T, oy + (r - 1) * T)
        end
        -- El moho va en el mismo suelo y nunca en la misma casilla que el
        -- barro (el tablero no lo deja crecer encima), asi que no hay orden
        -- que decidir entre los dos: donde hay uno no hay el otro.
        if board.moho[i] then
            local c, r = board:cr(i)
            Art.draw("moho", ox + (c - 1) * T, oy + (r - 1) * T)
        end
    end
end

-- El nombre del bol, grabado en el faldon.
--
-- Se dibuja en VIRTUAL y no dentro del `scale` del arte porque es TEXTO: la
-- fuente ya viene en pixeles de pantalla, y meterla en la rejilla del arte la
-- multiplicaria por cuatro. A cambio hay que pasarle el temblor del fotograma
-- convertido a virtual, que es lo que mantiene el nombre pegado al faldon
-- cuando el bol se sacude; sin eso, el nombre se queda quieto mientras el bol
-- tiembla y se lee como una pegatina que no es del bol.
local NOMBRE = { "K", "I", "K", "O" }

local function dibujarNombre(dx, dy)
    if faldon == 0 then return end
    local A = Constants.ART
    -- La cara del faldon: lo que queda entre el reborde (dos pixeles de arte)
    -- y el canto de abajo (uno).
    local cara, alto = (oy + board.rows * T + 6) * A, (faldon - 3) * A
    -- La fuente mediana si cabe entera; si no, la pequena. El faldon no se
    -- estira para que quepa la letra: es el bol quien manda el alto.
    local font = (alto >= Fonts.medium:getHeight()) and Fonts.medium or Fonts.small
    love.graphics.setFont(font)

    -- Las letras se dibujan UNA A UNA. "K I K O" con espacios da el espaciado
    -- de la fuente, que a este tamano deja las letras casi pegadas de dos en
    -- dos; el hueco fijo es lo que hace que se lean como cuatro letras
    -- separadas -- que es como se lee un nombre estampado en metal.
    local hueco = math.floor(font:getHeight() * 0.45)
    local ancho = -hueco
    for _, l in ipairs(NOMBRE) do ancho = ancho + font:getWidth(l) + hueco end

    local x = math.floor((ox + board.cols * T / 2) * A - ancho / 2) + dx
    local y = math.floor(cara + (alto - font:getHeight()) / 2) + dy

    for _, l in ipairs(NOMBRE) do
        -- Grabado, no impreso: la copia CLARA va debajo y a la derecha y la
        -- oscura encima. La luz del bol cae arriba a la izquierda, asi que una
        -- incision tiene la sombra en su canto de arriba y el brillo en el de
        -- abajo; invertir las dos copias convierte el grabado en relieve.
        love.graphics.setColor(Palette.metalShine)
        love.graphics.print(l, x + 1, y + 2)
        love.graphics.setColor(Palette.metalDark)
        love.graphics.print(l, x, y)
        x = x + font:getWidth(l) + hueco
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Donde va la pizarra del arcade, en virtual: la cara del faldon, o un panel
-- encima de la ultima fila si el faldon no cabe.
local function rectPizarra()
    local A = Constants.ART
    if faldon > 0 then
        return { x = (ox - 4) * A, y = (oy + board.rows * T + 6) * A,
                 w = (board.cols * T + 8) * A, h = (faldon - 3) * A }, false
    end
    local h = Fonts.medium:getHeight() + 12
    return { x = ox * A, y = (oy + board.rows * T) * A - h - 4, w = board.cols * T * A, h = h }, true
end

local function dibujarPiezas()
    love.graphics.setColor(1, 1, 1, 1)

    -- La casilla elegida: un marco que late. No se agranda la galleta, se marca
    -- la CASILLA: agrandar la galleta la mueve, y una galleta que se mueve sola
    -- se confunde con una que esta cayendo.
    if seleccion and board.mascara[seleccion] then
        local c, r = board:cr(seleccion)
        local latido = math.floor(math.abs(math.sin(love.timer.getTime() * 6)) * 2)
        love.graphics.setColor(Palette.miga)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", ox + (c - 1) * T - latido, oy + (r - 1) * T - latido,
                                T + latido * 2, T + latido * 2)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- La casilla a la que apunta el arrastre del arcade, mientras la pizarra
    -- ensena lo que daria: un marco fijo, sin latido, para que se lea como
    -- "aqui" y no como otra casilla elegida.
    if arrastre and arrastre.destino and board.mascara[arrastre.destino] then
        local c, r = board:cr(arrastre.destino)
        love.graphics.setColor(Palette.gold)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", ox + (c - 1) * T, oy + (r - 1) * T, T, T)
        love.graphics.setColor(1, 1, 1, 1)
    end

    for _, p in ipairs(moribundas) do
        Art.drawScaled(spriteDe(p), p.x, p.y, p.ex, p.ey)
    end

    for _, p in pairs(piezas) do
        local ex, ey = p.ex, p.ey
        -- El cubito no lo dibuja `spriteDe`: es un sprite APARTE encima de la
        -- galleta, con la misma escala que ella. Son dos dibujos y no uno
        -- porque dentro del hielo puede estar cualquiera de las veinticinco
        -- galletas, y una copia congelada de cada una son veinticinco sprites
        -- mas que mantener.
        -- La pista no dibuja flechas ni carteles: hace latir las dos galletas
        -- de la jugada. Se entiende sin leer nada y no tapa el tablero.
        if pista and (p == piezas[board.celdas[pista.i] and board.celdas[pista.i].id]
                      or p == piezas[board.celdas[pista.j] and board.celdas[pista.j].id]) then
            local k = 1 + math.abs(math.sin(pista.t * 5)) * 0.18
            ex, ey = ex * k, ey * k
        end
        Art.drawScaled(spriteDe(p), p.x, p.y, ex, ey)
        if p.hielo then Art.drawScaled("hielo", p.x, p.y, ex, ey) end
    end
end

-- Dejar la partida de arcade: se apunta la marca y se vuelve a la portada.
-- Abandonar cuenta como perder -- se ha llegado hasta donde se ha llegado --
-- porque lo contrario seria que salirse a tiempo guardara una marca mejor que
-- jugar la ronda siguiente.
function abandonar()
    if run then
        -- Los puntos de la ronda en curso solo se suman si la ronda NO ha
        -- terminado: una ronda ganada ya los metio en el bote (`rondaGanada`),
        -- y sumarlos otra vez al salirse convertiria el boton de dejarlo en la
        -- forma de sacar la mejor marca.
        local sueltos = (estado == "jugando") and progreso.puntos or 0
        Session.apuntarArcade(run.ronda, run.puntos + sueltos)
    end
    ScreenManager.switch(run and "portada" or "mapa")
end

-- Y lo que hace ahora la tecla de atras y el boton de SALIR: preguntar.
--
-- Irse de un nivel es lo mas caro que se puede tocar sin querer en todo el
-- juego -- en la campana se pierde el nivel entero, y en el arcade la partida
-- --, y hasta ahora se iba al primer toque. En el telefono ademas ni siquiera
-- hace falta un toque: el gesto de atras del sistema entra por la misma
-- puerta (`Juego.keypressed`) y lo hace un dedo que rozaba el canto.
--
-- Tambien con el cartel del final delante, y no es de mas: irse ahi despues de
-- ganar una ronda del arcade tira la mejora que se acaba de ganar.
function pedirSalir()
    confirmar = true
end

-- La pregunta. Sale de las mismas piezas que el cartel del final -- velo,
-- panel, perro, dos botones -- porque es ese cartel con menos dentro; hacerle
-- unas suyas seria tener dos paneles parecidos que se separan en cuanto se
-- toque uno.
--
-- Dos cosas cambian, y las dos son el orden. El boton de arriba es SEGUIR, que
-- es lo que quiere quien ha llegado aqui sin querer -- en el cartel del final
-- arriba va lo que uno quiere, y aqui eso es no haber tocado nada --, y el de
-- irse va abajo y en papel, como todas las salidas del juego.
local function dibujarConfirmar()
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    UI.velo(0.78)

    local ancho = W - 60
    -- Lo justo para el titulo, la cara y los dos botones. Es mas bajo que el
    -- del final porque aqui no hay nada que contar: ni estrellas, ni puntos,
    -- ni la ronda que viene.
    local alto = 440
    local x, y = 30, H / 2 - alto / 2

    UI.panel(x, y, ancho, alto)
    -- Lo que se deja no es lo mismo en los dos modos, y la cabecera de detras
    -- ya lo esta diciendo: alli pone "Nivel 7" o "Ronda 7". Preguntar por el
    -- nivel en el arcade seria la pregunta de otra pantalla.
    UI.textoCentro(run and "¿Dejar la partida?" or "¿Dejar el nivel?",
                   W / 2, y + 24, Palette.red, Fonts.medium)

    -- El perro de la pregunta, en el mismo sitio y a la misma escala que el
    -- del cartel del final: son el mismo cartel y la cara no puede saltar de
    -- uno a otro.
    local kw, kh = Art.size(dudoso:id())
    dudoso:dibujar(W / 2 - kw * Constants.ART / 2, y + 84, Constants.ART)

    -- Lo que cuesta decir que si, que es distinto en cada modo y es lo unico
    -- que hace falta saber para contestar.
    UI.textoCentro(run and "se apunta la marca y se acaba" or "el nivel se queda a medias",
                   W / 2, y + 84 + kh * Constants.ART + 14, Palette.dim, Fonts.tiny)

    local bw, bh = ancho - 60, 66
    local bx = x + 30
    local by = y + alto - bh * 2 - 34

    if UI.boton(bx, by, bw, bh, "Seguir jugando", { tono = Palette.green }) then
        confirmar = false
    end
    if UI.boton(bx, by + bh + 12, bw, bh, "Salir", { tono = Palette.uiLine }) then
        abandonar()
    end
end

-- El panel de fin de RONDA del arcade. Es el del nivel con otras cuentas: no
-- hay estrellas que ensenar (no las hay) y el boton de arriba no lleva al
-- nivel siguiente sino a la pausa, que es donde se elige la mejora. Lo que se
-- ensena en su sitio son las dos cifras que cuentan en una partida larga: lo
-- que ha dado esta ronda y lo que lleva la partida entera.
local function dibujarFinalArcade()
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    UI.velo(0.78)

    local gano = estado == "ganado"
    local ancho = W - 60
    -- Mas alto que antes, y lo que ha crecido es la cara: la de la hoja mide
    -- treinta y dos pixeles de arte y no veinticuatro, y a escala de tablero
    -- son ciento veintiocho de alto. Bajarla de escala para que cupiera en el
    -- panel de antes habria dejado al perro del cartel con un pixel distinto
    -- del de la cabecera que se ve detras del velo.
    local alto = 520
    local x, y = 30, H / 2 - alto / 2
    local marca = Session.arcade()
    local total = run.puntos + (gano and 0 or progreso.puntos)

    UI.panel(x, y, ancho, alto)
    UI.textoCentro(gano and string.format("¡Ronda %d superada!", run.ronda) or "Fin de la partida",
                   W / 2, y + 24, gano and Palette.gold or Palette.red, Fonts.medium)

    -- Kiko en medio del panel y no una hilera de estrellas: en el arcade no hay
    -- tres hitos que ensenar, hay un perro que ha comido o no ha comido. Y es
    -- EL MISMO perro de la cabecera -- el objeto, no otro igual --, asi que la
    -- cara con la que acaba la ronda ya la puso `animoDeKiko` al terminar: si
    -- el cartel eligiera la suya, habria dos sitios decidiendo la misma cosa y
    -- solo se notaria el dia que se contradijeran.
    local s = Constants.ART
    local kw, kh = Art.size(kiko:id())
    kiko:dibujar(W / 2 - kw * s / 2, y + 84, s)

    local yt = y + 84 + kh * s + 14
    if gano then
        UI.textoCentro(string.format("%d puntos en la ronda", progreso.puntos), W / 2, yt,
                       Palette.text, Fonts.small)
        UI.textoCentro(string.format("%d en la partida", run.puntos), W / 2,
                       yt + Fonts.small:getHeight() + 6, Palette.dim, Fonts.tiny)
        UI.textoCentro(string.format("la ronda %d pide %d", run.ronda + 1,
                                     Arcade.meta(run.ronda + 1)),
                       W / 2, yt + Fonts.small:getHeight() + 6 + Fonts.tiny:getHeight() + 8,
                       Palette.gold, Fonts.tiny)
    else
        UI.textoCentro(string.format("Ronda %d", run.ronda), W / 2, yt, Palette.text, Fonts.small)
        UI.textoCentro(string.format("%d puntos  ·  mejor: ronda %d", total,
                                     math.max(marca.ronda, run.ronda)),
                       W / 2, yt + Fonts.small:getHeight() + 6, Palette.dim, Fonts.tiny)
    end

    local bw, bh = ancho - 60, 66
    local bx = x + 30
    local by = y + alto - bh * 2 - 34

    if gano then
        if UI.boton(bx, by, bw, bh, "Elegir mejora") then
            ScreenManager.switch("mejoras", run)
        end
        if UI.boton(bx, by + bh + 12, bw, bh, "Dejarlo", { tono = Palette.uiLine }) then
            abandonar()
        end
    else
        if UI.boton(bx, by, bw, bh, "Otra partida", { tono = Palette.green }) then
            Juego.enter(1, Arcade.nuevo(os.time()))
        end
        if UI.boton(bx, by + bh + 12, bw, bh, "Portada", { tono = Palette.uiLine }) then
            ScreenManager.switch("portada")
        end
    end
end

-- El panel de fin de nivel. Sale sobre un velo y con los botones abajo, donde
-- llega el pulgar: es la unica pantalla del juego que aparece sin que nadie la
-- haya pedido, y por eso sus botones no pueden estar donde estaba el tablero.
local function dibujarFinal()
    if run then return dibujarFinalArcade() end
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    UI.velo(0.78)

    local gano = estado == "ganado"
    local ancho = W - 60
    -- El panel crecio lo que ocupa la cara (ver el del arcade): ciento
    -- veintiocho de perro y el aire de debajo.
    local alto = 580
    local x, y = 30, H / 2 - alto / 2

    UI.panel(x, y, ancho, alto)
    UI.textoCentro(gano and "¡Nivel superado!" or "Se acabaron los movimientos",
                   W / 2, y + 24, gano and Palette.gold or Palette.red,
                   gano and Fonts.large or Fonts.small)

    -- Kiko ENCIMA de las estrellas, y es el mismo perro de la cabecera con la
    -- cara que ya tiene puesta. Las estrellas dicen cuanto has sacado y tardan
    -- en leerse tres miradas; la cara dice si ha salido bien y se lee sin
    -- mirar. Debajo del titulo, que es lo que el titulo esta contando.
    --
    -- El cartel de la campana no tenia perro y el del arcade si, y eso era lo
    -- raro: el que mas falta hace es el de aqui, porque perder un nivel es lo
    -- unico de este juego que pasa sin que nadie lo pida.
    local kw, kh = Art.size(kiko:id())
    kiko:dibujar(W / 2 - kw * Constants.ART / 2, y + 84, Constants.ART)
    local yEstrellas = y + 84 + kh * Constants.ART + 12

    -- Las estrellas se enseñan siempre, tambien al perder: son puntos, y los
    -- puntos se han hecho igual. Enseñarlas solo al ganar convierte una
    -- partida perdida en una partida que no ha pasado.
    local s = 4
    local ew = select(1, Art.size("estrella")) * s
    for k = 1, 3 do
        local id = k <= Juego.estrellasGanadas and "estrella" or "estrellaOff"
        local ex = W / 2 + (k - 2) * (ew + 16)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Art.get(id), math.floor(ex - ew / 2), math.floor(yEstrellas), 0, s, s)
    end

    if not gano then
        -- El objetivo entero, y puede ocupar dos lineas: un nivel puede pedir
        -- dos cosas a la vez. Se apilan hacia ARRIBA desde donde caia la unica
        -- linea de antes, que es lo que deja intacto el hueco de los puntos --
        -- creciendo hacia abajo, la segunda linea se comeria la cifra gorda.
        local lineas = UI.lineas("faltaba: " .. Levels.textoObjetivo(def),
                                 ancho - 40, Fonts.tiny)
        local paso = Fonts.tiny:getHeight() + 4
        for k, linea in ipairs(lineas) do
            UI.textoCentro(linea, W / 2, yEstrellas + 64 - (#lineas - k) * paso,
                           Palette.dim, Fonts.tiny)
        end
    end

    local yPuntos = yEstrellas + 104
    UI.textoCentro(string.format("%d puntos", progreso.puntos), W / 2, yPuntos,
                   Palette.text, Fonts.medium)
    UI.textoCentro(string.format("mejor: %d", math.max(Session.puntos(numero), progreso.puntos)),
                   W / 2, yPuntos + Fonts.medium:getHeight() + 6, Palette.dim, Fonts.tiny)

    local bw, bh = ancho - 60, 66
    local bx = x + 30
    local by = y + alto - bh * 2 - 34

    -- El boton de arriba es SIEMPRE el que el jugador quiere: seguir si ha
    -- ganado, volver a intentarlo si ha perdido. El de abajo es el mapa, que
    -- es de lo que uno se arrepiente si lo toca sin querer.
    if gano and numero < Levels.total then
        if UI.boton(bx, by, bw, bh, "Siguiente nivel") then
            Juego.enter(numero + 1)
        end
    elseif gano then
        if UI.boton(bx, by, bw, bh, "Volver a jugarlo", { tono = Palette.green }) then
            Juego.enter(numero)
        end
    else
        if UI.boton(bx, by, bw, bh, "Reintentar", { tono = Palette.green }) then
            Juego.enter(numero)
        end
    end

    if UI.boton(bx, by + bh + 12, bw, bh, "Mapa", { tono = Palette.uiLine }) then
        ScreenManager.switch("mapa")
    end
end

function Juego.draw()
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    love.graphics.clear(Palette.uiBack)

    -- El fondo: bandas anchas de mantel. Van en virtual y no en arte porque no
    -- son arte, son papel pintado: si se dibujaran en la rejilla del tablero
    -- competirian con el. Y el contraste entre las dos bandas es minimo a
    -- proposito: el fondo esta detras de un tablero de pasteles y cualquier
    -- raya que se lea de verdad se lee como parte del juego.
    for k = 0, math.ceil(H / 96) do
        love.graphics.setColor(k % 2 == 0 and Palette.fondoAlt or Palette.fondo)
        love.graphics.rectangle("fill", 0, k * 96, W, 96)
    end
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.push()
    love.graphics.scale(Constants.ART, Constants.ART)
    local sx, sy = Efectos.sacudida()
    love.graphics.translate(sx, sy)
    dibujarTablero()
    dibujarPiezas()
    Efectos.drawArte()
    particulas:draw()
    love.graphics.pop()

    -- El nombre va DESPUES del pop: es texto y vive en virtual. `sx, sy` es el
    -- temblor de ESTE fotograma -- `Efectos.sacudida()` devuelve un valor
    -- distinto cada vez que se llama, asi que se pide una sola vez y se
    -- reparte.
    --
    -- En el arcade el faldon es tambien la PIZARRA (`src/pizarra.lua`): la
    -- previa, la cuenta pendiente y la secuencia de cada movimiento. Mientras
    -- ensena algo, el nombre no se graba. Sin faldon (lienzo corto), la pizarra
    -- va en un panel encima de la ultima fila del tablero.
    local rect, fondo = rectPizarra()
    if not (run and Pizarra.draw(rect, fondo)) then
        dibujarNombre(sx * Constants.ART, sy * Constants.ART)
    end

    -- La cifra de puntos se la da el marcador ya resuelta: la cabecera pinta
    -- lo que le llega y no sabe que hay una cuenta en marcha.
    local puntos, escala, color = Efectos.cuenta()
    Hud.draw(def, numero, progreso, movimientos,
             { puntos = puntos, escala = escala, color = color }, kiko)
    Efectos.drawVirtual()
    if run and Hud.puntosX then
        Pizarra.drawVuelo(rect.x + rect.w / 2, rect.y + rect.h / 2, Hud.puntosX, Hud.puntosY)
    end

    -- Salir del nivel. Abajo a la izquierda, pequeno y sin color: es la unica
    -- cosa de esta pantalla que el jugador NO quiere tocar por accidente.
    local bw, bh = 150, 56
    local by = Constants.GAME_HEIGHT - Constants.SAFE_BOTTOM - bh - 12
    -- Cada capa apaga la de debajo: el cartel del final apaga el boton de
    -- salir, y la pregunta los apaga a los dos. Un boton que contesta por
    -- detras de un velo es la forma de que un mismo dedo haga dos cosas.
    UI.lock(confirmar or estado ~= "jugando")
    if UI.boton(18, by, bw, bh, "SALIR", { tono = Palette.uiLine, font = Fonts.small }) then
        pedirSalir()
    end

    if estado ~= "jugando" then
        UI.lock(confirmar)
        dibujarFinal()
    end

    if confirmar then
        UI.lock(false)
        dibujarConfirmar()
    end
end

return Juego
