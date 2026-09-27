-- La pausa entre rondas del arcade: tres cartas, se elige una.
--
-- Una de tres y no una lista con todo: lo que hace que una partida se recuerde
-- es haber tenido que dejar algo, y con el pool entero delante no se deja
-- nada, se ordena. Las tres salen de `src/arcade.lua`, que es quien sabe lo
-- que hay y hasta donde puede subir cada cosa; aqui solo se pintan.
--
-- La carta dice tres cosas y en este orden: que es (el icono, que es el sprite
-- que ya se ha visto en el tablero), como se llama, y QUE HARA -- no lo que
-- hace en general, sino el numero al que subiria si se cogiera ahora. "Cada
-- galleta vale 90 en vez de 60" se decide en un segundo; "mejora la puntuacion
-- base" hay que pensarlo, y esto es una pausa de diez segundos entre dos
-- rondas.
--
-- Los puntos de la linea van a la derecha con las mismas estrellas del mapa:
-- dicen cuanto queda de esa mejora, que es la unica manera de saber que una
-- carta se esta acabando y hay que cogerla ahora.
--
-- Las tres cosas van en MAYUSCULAS, y el cuerpo con la letra de un boton
-- (`small`) y no con la mas pequena del juego: una carta es lo que se aprieta,
-- y lo que se aprieta se lee de un vistazo o no se aprieta. A ese tamano el
-- cuerpo ocupa dos lineas siempre, y se reparte por la mitad (`UI.dosLineas`).
--
-- Y una carta es una GALLETA de interfaz, la misma que un boton y sacada de la
-- misma funcion (`UI.galleta`): mismo canto a escalones, misma falda que el
-- dedo hunde, mismo rebote al soltar. Aqui las tres cartas son lo unico que se
-- puede tocar, asi que tienen que responder al dedo como responde todo lo
-- demas del juego.

local Constants = require("src.constants")
local Palette   = require("src.palette")
local Arcade    = require("src.arcade")
local Session   = require("src.session")
local UI        = require("src.ui")
local Art       = require("src.art")
local Sfx       = require("src.sfx")
local ScreenManager = require("lib.screen_manager")

local Mejoras = {}

local run
local entrada          -- lo que llevan las cartas subiendo desde abajo

-- Lo que tarda una carta en entrar y lo que se retrasa la siguiente. Las tres
-- entran escalonadas por la misma razon que el tablero cae escalonado: tres
-- cartas que aparecen a la vez son un panel, y tres que llegan una detras de
-- otra son tres cosas entre las que hay que elegir.
local T_ENTRADA = 0.22
local T_PASO    = 0.07

function Mejoras.enter(partida)
    run = partida
    if not run.oferta then Arcade.ofrecer(run) end
    entrada = 0
end

function Mejoras.update(dt)
    entrada = entrada + dt
end

function Mejoras.keypressed(key)
    if key == "escape" then
        -- Salirse de la pausa es dejar la partida, y la marca se apunta igual:
        -- las rondas ganadas estan ganadas.
        Session.apuntarArcade(run.ronda, run.puntos)
        ScreenManager.switch("portada")
    end
end

-- Cuanto ha entrado la carta k, de 0 a 1.
local function asomada(k)
    local t = (entrada - (k - 1) * T_PASO) / T_ENTRADA
    if t < 0 then return 0 elseif t > 1 then return 1 end
    -- Frena al llegar (quadout): una carta que llega a velocidad constante se
    -- lee como un elemento colocandose y no como una carta que se posa.
    return 1 - (1 - t) * (1 - t)
end

local ALTO_CARTA = 148

local function dibujarCarta(mejora, k, x, y, w)
    local h = ALTO_CARTA
    local t = asomada(k)
    if t <= 0 then return false end
    -- Entra desde abajo y no desde un lado: el dedo esta abajo y la carta
    -- llega de donde va a estar la mano.
    y = y + math.floor((1 - t) * 60)

    local nivel = Arcade.siguienteNivel(run, mejora.id)

    -- La carta es una galleta de interfaz como cualquier boton, y sale del
    -- mismo sitio: canto a escalones, falda debajo que el dedo hunde, rebote
    -- al soltar. Antes era un rectangulo con `UI.borde` -- una linea VECTORIAL
    -- de LÖVE, el unico canto suavizado que quedaba en la interfaz -- y un
    -- hundimiento de dos pixeles virtuales puestos a ojo; al lado del boton
    -- `Seguir` de esta misma pantalla se leia como de otro juego.
    --
    -- En PAPEL y no en oro, aunque las tres cartas sean lo unico que se puede
    -- tocar aqui y el oro sea el color de lo importante. La razon es medible:
    -- la estrella encendida de la derecha ES `Palette.gold`, asi que sobre una
    -- cara dorada no queda floja, DESAPARECE -- y esos puntos son lo unico que
    -- avisa de que una mejora se esta acabando y hay que cogerla ahora. El oro
    -- de la pantalla se queda donde se lee: el titulo, el icono y los puntos.
    --
    -- `quieto` mientras entra, por lo de siempre: una carta a medio entrar que
    -- ya responde al dedo se lleva el toque con el que el jugador queria
    -- cerrar el panel de la ronda anterior.
    local tocado, ix, iy, iw, ih = UI.galleta(mejora.id, x, y, w, h,
                                              { tono = Palette.uiLine, quieto = t < 1 })

    -- El icono, a la izquierda y a escala de arte: es el mismo sprite que va a
    -- salir en el tablero, y verlo aqui es la mitad de la explicacion.
    --
    -- La escala se saca del HUECO y no de `Constants.ART` a secas. Casi todos
    -- los iconos son galletas de dieciseis y la cuenta da cuatro, que es lo
    -- que habia escrito antes; el que no lo es -- la cara de Kiko de "Mano
    -- larga", que mide treinta y dos -- a escala de arte ocuparia la carta
    -- entera. Asi la caja del icono mide lo mismo en las tres cartas, que es lo
    -- que mantiene el texto de todas empezando en la misma columna.
    local CAJA = Constants.TILE * Constants.ART
    local aw, ah = Art.size(mejora.icono)
    local escala = math.max(1, math.floor(CAJA / math.max(aw, ah)))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Art.get(mejora.icono),
                       math.floor(ix + 16 + (CAJA - aw * escala) / 2),
                       math.floor(iy + (ih - ah * escala) / 2),
                       0, escala, escala)

    -- Todo lo que dice la carta va en MAYUSCULAS y el cuerpo sube a `small`. El
    -- cuerpo es la frase que hay que leer para elegir, y estaba escrita con la
    -- letra mas pequena del juego (`tiny`, dieciseis pixeles) en caja baja, que
    -- en esta fuente tiene una equis de SIETE pixeles de alto: lo que engorda
    -- una letra de pixeles no es tanto el cuerpo como la caja, y subir las dos
    -- cosas es lo que hace que la carta se lea de un vistazo y no leyendola.
    --
    -- A este tamano no cabe de una linea NINGUNO de los textos posibles (se
    -- midieron los sesenta y siete), asi que se parte -- y se parte por la
    -- mitad y no por el borde, que es lo que hace `UI.dosLineas`: partida por
    -- el borde, casi todas las cartas se quedarian con una sola palabra en la
    -- segunda linea.
    local tx = ix + 16 + CAJA + 18
    local cuerpo = UI.dosLineas(UI.mayus(mejora.texto(nivel)),
                                ix + iw - 16 - tx, Fonts.small)

    -- El bloque va CENTRADO en la cara, a la altura del icono. Colgado del
    -- canto de arriba -- que es donde estaba -- el nombre y su linea acaban a
    -- media carta y dejan cincuenta pixeles muertos debajo, y una carta con el
    -- peso arriba se lee como un panel al que le falta algo.
    local paso = Fonts.small:getHeight() + 2
    local alto = Fonts.medium:getHeight() + 8
                 + Fonts.small:getHeight() + (#cuerpo - 1) * paso
    local ty = iy + math.floor((ih - alto) / 2)

    UI.texto(UI.mayus(mejora.nombre), tx, ty, Palette.text, Fonts.medium)
    for k, linea in ipairs(cuerpo) do
        UI.texto(linea, tx, ty + Fonts.medium:getHeight() + 8 + (k - 1) * paso,
                 Palette.dim, Fonts.small)
    end

    -- Los puntos de la linea: uno por nivel, encendidos los que ya se tienen y
    -- el que se llevaria ahora. El que se llevaria va en la misma estrella
    -- encendida a proposito -- la carta ensena como quedaria la mejora si se
    -- coge, no como esta.
    --
    -- A la altura del NOMBRE y no del centro de la carta: los puntos dicen
    -- cuanto queda de esa mejora, asi que se leen en la misma pasada que su
    -- nombre y no como una fila suelta a la derecha.
    local s = 2
    local ew, eh = Art.size("estrella")
    ew, eh = ew * s, eh * s
    local ey = ty + math.floor((Fonts.medium:getHeight() - eh) / 2)
    for n = 1, mejora.tope do
        local id = n <= nivel and "estrella" or "estrellaOff"
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Art.get(id), math.floor(ix + iw - 16 - (mejora.tope - n + 1) * (ew + 4)),
                           ey, 0, s, s)
    end

    return tocado
end

function Mejoras.draw()
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    love.graphics.clear(Palette.uiBack)
    for k = 0, math.ceil(H / 96) do
        love.graphics.setColor(k % 2 == 0 and Palette.fondoAlt or Palette.fondo)
        love.graphics.rectangle("fill", 0, k * 96, W, 96)
    end
    love.graphics.setColor(1, 1, 1, 1)

    local y = Constants.SAFE_TOP + 24
    UI.textoCentro("Elige una mejora", W / 2, y, Palette.gold, Fonts.large)
    y = y + Fonts.large:getHeight() + 6

    -- Lo que viene, con todas sus letras: la pausa se entiende mirando el
    -- numero que hay que pasar, no el que se acaba de pasar. Va a `small` como
    -- el cuerpo de las cartas -- son los numeros contra los que se elige, y a
    -- `tiny` se leian como el pie de pagina de la pantalla. Mide 492 px en el
    -- peor caso (ronda 30 y seis cifras de meta), asi que cabe de una linea en
    -- los 540 del lienzo; el pie de abajo se queda en `tiny` a proposito: ese
    -- no se lee para decidir, se consulta.
    local siguiente = run.ronda + 1
    UI.textoCentro(string.format("ronda %d  ·  %d puntos  ·  %d movimientos",
                                 siguiente, Arcade.meta(siguiente), Arcade.movimientos(run)),
                   W / 2, y, Palette.dim, Fonts.small)
    y = y + Fonts.small:getHeight() + 22

    -- Las cartas se centran en lo que queda entre la cabecera y el pie: en un
    -- lienzo largo, colgadas de la cabecera, el dedo tiene que subir hasta
    -- arriba para elegir y media pantalla se queda vacia debajo.
    local w = W - 48
    local x = 24
    local altoCartas = #(run.oferta or {}) * ALTO_CARTA + (#(run.oferta or {}) - 1) * 14
    local libre = (H - Constants.SAFE_BOTTOM - 70) - y
    if libre > altoCartas then y = y + math.floor((libre - altoCartas) / 2) end

    local elegida = nil
    for k, mejora in ipairs(run.oferta or {}) do
        if dibujarCarta(mejora, k, x, y + (k - 1) * (ALTO_CARTA + 14), w) then
            elegida = mejora.id
        end
    end

    -- Sin cartas no hay eleccion que ofrecer (estan todas al tope): la pausa se
    -- convierte en un boton de seguir. Pasa en una partida muy larga y es el
    -- unico final decente que tiene ese caso.
    if #(run.oferta or {}) == 0 then
        if UI.boton(x, y, w, 88, "Seguir", { font = Fonts.large }) then
            Sfx.play("toque", 1.4)
            Arcade.saltar(run)
            ScreenManager.switch("juego", 1, run)
        end
    end

    if elegida then
        Sfx.play("campana", 1.5)
        Arcade.tomar(run, elegida)
        ScreenManager.switch("juego", 1, run)
    end

    -- Lo que ya se lleva, en una linea y abajo del todo. No es un inventario
    -- -- no hace falta gestionarlo -- es la partida contada en cuatro palabras,
    -- y es lo que hace que la carta que repite una linea que ya tienes se lea
    -- como subirla y no como una carta nueva.
    --
    -- Va en lineas de tres y creciendo hacia ARRIBA desde el canto de abajo: en
    -- una partida larga se llevan ocho mejoras, y en una sola linea la ultima
    -- se sale del lienzo sin que se vea que se ha salido.
    local partes = {}
    for _, mejora in ipairs(Arcade.MEJORAS) do
        local n = run.mejoras[mejora.id]
        if n then partes[#partes + 1] = string.format("%s %d", mejora.nombre, n) end
    end
    local lineas = {}
    for k = 1, #partes, 3 do
        lineas[#lineas + 1] = table.concat(partes, "  ·  ", k, math.min(k + 2, #partes))
    end
    local alto = Fonts.tiny:getHeight() + 4
    local yPie = H - Constants.SAFE_BOTTOM - 16 - #lineas * alto
    for k, linea in ipairs(lineas) do
        UI.textoCentro(linea, W / 2, yPie + (k - 1) * alto, Palette.dim, Fonts.tiny)
    end
end

return Mejoras
