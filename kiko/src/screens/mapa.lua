-- El mapa: el camino de niveles.
--
-- Serpentea, y antes era una rejilla. La rejilla decia DONDE esta cada nivel;
-- el camino dice de donde vienes y hacia donde vas, que en una campana de
-- cien niveles es la mitad de la razon para seguir. Lo que la rejilla
-- hacia bien -- volver al 12 a sacarle la tercera estrella sin buscarlo -- no
-- se ha perdido, se paga de otra forma: el mapa se ABRE en el nivel que toca
-- en vez de por el principio, y el arrastre lleva impulso. Sin esas dos cosas
-- un camino de catorce mil pixeles es un castigo cada vez que se abre, y eso
-- era exactamente lo que la rejilla evitaba.
--
-- El nivel 1 esta ABAJO y el camino sube. Es lo que convierte el arrastre en
-- avanzar: al empujar el mapa hacia abajo con el pulgar, lo que asoma por
-- arriba es lo que falta. Al reves -- el 1 arriba, como una lista -- subir de
-- nivel es bajar por la pantalla, y entonces el camino no sube a ningun lado.
--
-- Todo el camino esta dibujado en pixeles GORDOS de lado `U`, el mismo pixel
-- de arte que el tablero: los nodos son discos de `UI.fichaPixel` (canto, luz
-- arriba, sombra abajo -- la receta de cualquier galleta) y el reguero entre
-- dos nodos son migas del mismo pixel. Un camino trazado con
-- lineas de LÖVE seria lo unico suavizado de todo el juego.
--
-- Y los nodos se HUNDEN debajo del dedo, con el mismo reloj que un boton
-- (`UI.pulsado`). No es adorno: son cien galletas apretables en la
-- pantalla donde mas se aprieta, y sin hundimiento son el unico sitio del
-- juego donde apretar no contesta nada.
--
-- Un nodo no lleva mas letra que su NUMERO. Los niveles tienen nombre en
-- `src/levels.lua` ("Primer bol", "Nevera") pero es una etiqueta interna y no
-- sale en ninguna pantalla: lo que identifica un nivel para quien juega es
-- donde cae en este camino y el numero que lleva dentro. Cien rotulos
-- a lo largo de la cuesta serian cien cosas mas que leer para
-- encontrar la unica que importa, que es el nodo de oro.
--
-- Lo que si hereda del original es que un nivel cerrado SE VE, con su numero
-- dentro: saber que vienen ocho mas es la otra mitad de la razon para seguir.

local Constants = require("src.constants")
local Palette   = require("src.palette")
local Levels    = require("src.levels")
local Session   = require("src.session")
local UI        = require("src.ui")
local Art       = require("src.art")
local Kiko      = require("src.kiko")
local Sfx       = require("src.sfx")
local ScreenManager = require("lib.screen_manager")

local Mapa = {}

-- El pixel gordo del mapa es el del arte: un nodo dibujado con pixeles de otro
-- tamano que los del tablero se lee como de otro juego.
local U      = 4
local R      = 8          -- radio del nodo, en pixeles gordos: 64 px de lado
local PASO   = 140        -- lo que sube el camino de un nivel al siguiente
local ARRIBA = 76         -- aire por encima del ultimo nodo
local ABAJO  = 104        -- y por debajo del primero, donde cuelga su chapa

-- Donde cae cada miga entre un nodo y el siguiente, en fraccion
-- del tramo. NO van repartidas de punta a punta: las de los extremos se meten
-- hacia dentro hasta librar el canto del nodo, que si no se come media miga
-- y deja el reguero saliendo de una muesca en vez de del centro de la ficha.
local MIGAS   = { 0.29, 0.43, 0.57, 0.71 }

local scroll, arrastre, impulso = 0, nil, 0
local tragarToque = false
local tiempo = 0

--== El trazado ============================================================

-- El serpenteo, en funcion del nivel `t` -- que se pide tambien en fracciones,
-- porque las migas salen de la MISMA curva que los nodos. Si cada
-- uno calculara su sitio por su lado, el reguero pasaria al lado del nodo en
-- vez de por dentro, y eso no se ve como un desajuste: se ve como un camino
-- roto.
--
-- Dos senos y no uno. El rapido da el vaiven -- una ida y vuelta cada cinco
-- nodos, que es lo que hace falta para que la ese entre entera en la pantalla:
-- mas lento, seis nodos seguidos tiran para el mismo lado y eso ya no es un
-- camino que serpentea, es una diagonal. El lento le corre el centro de sitio
-- y es lo unico que evita que los cien nodos repitan el mismo gesto
-- dieciocho veces; con uno solo, el camino se lee como una onda y no como un sitio.
local function caminoX(t)
    local izq = Constants.SAFE_LEFT + 74
    local der = Constants.GAME_WIDTH - Constants.SAFE_RIGHT - 74
    local cx, a = (izq + der) / 2, (der - izq) / 2
    return cx + (math.sin(t * 1.15) * 0.72 + math.sin(t * 0.41 + 2.1) * 0.28) * a
end

-- La altura, medida desde ARRIBA del contenido y hacia abajo, que es como
-- habla el scroll. El nivel mas alto va arriba del todo y el 1 al fondo.
local function caminoY(t)
    return ARRIBA + (Levels.total - t) * PASO
end

local function altoTotal()
    return ARRIBA + (Levels.total - 1) * PASO + ABAJO
end

function Mapa.cabecera()
    return Constants.SAFE_TOP + 132
end

-- El tope de abajo y el alto de la ventana por la que se ve el camino.
local function limites()
    local visible = Constants.GAME_HEIGHT - Mapa.cabecera() - Constants.SAFE_BOTTOM
    return math.min(0, visible - altoTotal()), visible
end

-- El scroll que deja el nivel `n` a media pantalla, un pelo por debajo del
-- centro: es donde llega el pulgar y donde cabe lo que le cuelga al nodo.
local function enfocar(n)
    local minimo, visible = limites()
    return math.max(minimo, math.min(0, visible * 0.58 - caminoY(n)))
end

--== Entrada ===============================================================

function Mapa.enter()
    arrastre, impulso, tragarToque, tiempo = nil, 0, false, 0
    -- El mapa se abre EN el nivel que toca. Con cien nodos el camino mide
    -- catorce mil pixeles, y abrirlo por un extremo son treinta arrastres
    -- antes de poder jugar.
    scroll = enfocar(math.min(Levels.total, Session.desbloqueado()))
end

function Mapa.press(x, y)
    -- Un toque que llega con el mapa lanzado lo PARA y no abre nada: si
    -- abriera, frenar el camino seria imposible sin entrar en un nivel.
    tragarToque = math.abs(impulso) > 40
    impulso = 0
    arrastre = { y = y, scroll = scroll, t = tiempo }
end

function Mapa.move(x, y)
    if not arrastre then return end
    local antes = scroll
    scroll = arrastre.scroll + (y - arrastre.y)
    -- La velocidad se mide del ULTIMO tramo y no de todo el arrastre: quien
    -- baja el mapa despacio y suelta parado no quiere que siga andando.
    local dt = tiempo - arrastre.t
    if dt > 0 then
        impulso = math.max(-4200, math.min(4200, (scroll - antes) / dt))
    end
    arrastre.t = tiempo
end

function Mapa.release()
    -- Un dedo que lleva parado un suspiro suelta sin impulso. Sin esto, parar
    -- el mapa con el dedo encima y levantarlo lo relanza con la velocidad que
    -- llevaba hace medio segundo.
    if arrastre and tiempo - arrastre.t > 0.08 then impulso = 0 end
    arrastre = nil
end

function Mapa.keypressed(key)
    -- Atras va a la portada y no al escritorio: desde que hay dos maneras de
    -- jugar, el mapa es una de ellas y no la puerta del juego.
    if key == "escape" then ScreenManager.switch("portada") end
end

function Mapa.resize()
    scroll = enfocar(math.min(Levels.total, Session.desbloqueado()))
end

function Mapa.update(dt)
    tiempo = tiempo + dt
    local minimo = limites()

    if not arrastre and impulso ~= 0 then
        scroll = scroll + impulso * dt
        impulso = impulso * math.exp(-4.5 * dt)
        -- Por debajo de esto el camino ya no se ve moverse y lo unico que hace
        -- el impulso es impedir que el tope lo recoja.
        if math.abs(impulso) < 12 then impulso = 0 end
    end

    -- El scroll se frena contra los topes en vez de cortarse: cortar se lee
    -- como que el camino se ha enganchado. Y el impulso muere ahi: un rebote
    -- que sigue empujando no vuelve nunca.
    if scroll > 0 then
        scroll = scroll * math.exp(-14 * dt)
        impulso = 0
    elseif scroll < minimo then
        scroll = minimo + (scroll - minimo) * math.exp(-14 * dt)
        impulso = 0
    end
end

--== Dibujo ================================================================

-- Los tres estados de un nodo, y los tres se distinguen por COLOR y no por
-- adorno: acero el cerrado, crema el pasado, oro el que toca. El acero es el
-- unico gris de una pantalla de cremas y por eso se lee como "todavia no" sin
-- necesidad de un candado encima del numero -- que ademas taparia el numero,
-- que es justo lo que hay que poder leer de un nivel que aun no se juega.
--
-- `cifra` es el color del numero y va en la misma fila que el resto por lo
-- mismo que el resto: sobre el acero y sobre el oro el numero va en crema y
-- sobre la crema en marron. La regla no es "oscuro sobre claro" -- el oro es
-- claro y el marron encima se lee mudo, que es el color que peor le sienta
-- justo al nodo que hay que encontrar al abrir el mapa.
local ESTADOS = {
    cerrado = { borde = Palette.ink, base = Palette.metal,
                luz = Palette.metalLite, sombra = Palette.metalDark,
                cifra = Palette.uiPanel },
    pasado  = { borde = Palette.ink, base = Palette.uiPanel,
                luz = Palette.miga, sombra = Palette.uiLine, brillo = Palette.miga,
                cifra = Palette.text },
    actual  = { borde = Palette.ink, base = Palette.gold,
                luz = Palette.goldLite, sombra = Palette.goldDark, brillo = Palette.miga,
                cifra = Palette.miga },
}

-- Las tres estrellas de un nivel, en una CHAPA colgada del canto de abajo del
-- nodo. La chapa hace dos cosas que no son adorno. Le da fondo a la estrella
-- APAGADA, que no es una estrella oscura sino un hueco con borde y sobre el
-- mantel crema casi no esta. Y para el reguero: el camino sale del nodo justo
-- por debajo, y una miga cruzando una estrella no se lee como dos
-- cosas que se tapan, se lee como una estrella rota.
--
-- Va siempre en crema, tambien bajo el nodo de oro: la estrella ganada es
-- dorada, y dorada sobre dorado no es una estrella floja, es ninguna. Pegada
-- al canto del nodo se lee igual como el pie de esa ficha aunque no comparta
-- su color.
local CHAPA_W, CHAPA_H = 76, 28

local function estrellasDe(x, y, n)
    UI.rectPixel(x - CHAPA_W / 2, y, CHAPA_W, CHAPA_H, Palette.ink, U)
    UI.rectPixel(x - CHAPA_W / 2 + U, y + U, CHAPA_W - 2 * U, CHAPA_H - 2 * U,
                 Palette.uiPanel, U, nil, UI.ESQUINA_DENTRO)

    local tengo = Session.estrellas(n)
    local s = 2
    local ew = select(1, Art.size("estrella")) * s
    -- Las estrellas se pisan dos pixeles entre si: la silueta deja un pixel de
    -- aire por lado, asi que a tope de sprite quedarian separadas cuatro y las
    -- tres no cabrian dentro de la chapa. Pisadas, el aire que se ve entre dos
    -- estrellas es el que dejo la silueta.
    for k = 1, 3 do
        local id = k <= tengo and "estrella" or "estrellaOff"
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Art.get(id),
                           math.floor(x + (k - 2) * (ew - 2) - ew / 2),
                           math.floor(y + 2), 0, s, s)
    end
end

-- Devuelve si se ha tocado y cuanto se ha hundido, en pixeles gordos: lo
-- segundo lo necesita el perro, que va encima y tiene que bajar con la ficha.
-- `tocable` es false cuando el toque se lo ha tragado el arrastre.
local function nodo(n, x, y, abierto, tocable)
    local cerrado = n > abierto
    local pasado = Session.pasado(n)
    -- El que toca -- el primero abierto sin pasar -- es el unico en oro y el
    -- unico con el perro encima: es lo unico que hay que buscar al abrir el
    -- mapa, y por eso no comparte aspecto con ningun otro.
    local actual = not cerrado and not pasado

    local tono = cerrado and ESTADOS.cerrado or (actual and ESTADOS.actual or ESTADOS.pasado)

    -- Un nodo se hunde debajo del dedo con el mismo reloj que un boton
    -- (`UI.pulsado`), y era lo unico apretable del juego que no lo hacia:
    -- cien fichas que parecen galletas, en la pantalla donde mas se
    -- aprieta, y ninguna contestaba al dedo.
    --
    -- Pero con falda de UNO y no de dos como un boton, que es la sombra que ya
    -- tenia. Dos obligarian a separar la ficha dos pixeles gordos de su chapa,
    -- y al apretarla el canto de abajo del disco se comeria la mitad de la
    -- estrella de en medio -- una estrella a medias no se lee como un nodo
    -- apretado, se lee como una estrella rota. Y no se pierde nada por bajar
    -- la falda: un nodo cabe ENTERO debajo del pulgar que lo aprieta, asi que
    -- el hundimiento no lo ve nadie mientras pasa; lo que de verdad se ve es
    -- el rebote al soltar, y ese es igual de alto en los dos casos.
    --
    -- La llave es el numero del nivel y no lleva el sitio: el mapa se arrastra
    -- y una llave con la posicion dentro cambiaria cada fotograma (ver
    -- `UI.pulsado`).
    local lado = R * U * 2
    local caida, _, tocado = UI.pulsado("nodo" .. n, x - lado / 2, y - lado / 2, lado, lado,
                                        { falda = 1, quieto = cerrado or not tocable })
    local dy = caida * U

    -- La chapa va DEBAJO del disco: asi el canto de la ficha la remata por
    -- arriba y las dos se leen como una pieza, en vez de como un cartel
    -- apoyado en un circulo. No se hunde con la ficha: es el suelo en el que
    -- la ficha se apoya, y una chapa que baja con ella convierte el
    -- hundimiento en un nodo que se cae del camino.
    if not cerrado and (pasado or Session.estrellas(n) > 0) then
        estrellasDe(x, y + R * U - U, n)
    end

    -- La sombra: el mismo disco un pixel gordo mas abajo, tirando a tinta. Sin
    -- ella el camino se lee plano, como pegatinas sobre el mantel en vez de
    -- fichas apoyadas encima. Y es tambien el FONDO de la falda: la ficha
    -- hundida aterriza justo encima y la tapa entera, que es lo que hace que
    -- hundirse se lea como meterse en su hueco.
    UI.discoPixel(x, y + U, R, Palette.mix(Palette.ink, Palette.fondo, 0.4), U)
    UI.fichaPixel(x, y + dy, R, U, tono)

    local font = Fonts.medium
    UI.textoCentro(tostring(n), x, y + dy - font:getHeight() / 2, tono.cifra, font)

    return tocado, caida
end

-- Kiko encima del nodo que toca, como quien esta parado ahi. Es el mismo
-- respingo de la portada -- un pixel de arte arriba y abajo, nunca medio --
-- porque es el mismo perro y tiene que respirar igual.
--
-- Con UNA cara y quieta, que es lo que trae el animo `mapa` (ver
-- `src/kiko.lua`): aqui ya se mueven el camino al arrastrarlo, los nodos al
-- hundirse y el mantel de detras, y un perro parpadeando en medio de eso es
-- una cosa mas pidiendo la mirada en la pantalla donde hay que encontrar UNA.
--
-- A escala tres y no cuatro: el nodo mide dieciseis pixeles de arte de ancho y
-- la cara treinta y dos, asi que a escala de tablero el perro seria el doble
-- de ancho que la ficha en la que esta parado y taparia la del nivel de
-- arriba.
local perro = Kiko.nuevo("mapa")

local function kiko(x, y)
    local esc = 3
    local kw, kh = Art.size(perro:id())
    local bote = math.floor(math.sin(tiempo * 2.2) * 1.4) * esc
    perro:dibujar(x - kw * esc / 2, y - R * U + U - kh * esc + bote, esc)
end

function Mapa.draw()
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    love.graphics.clear(Palette.uiBack)

    -- Las bandas del mantel se mueven con el camino, a un cuarto de su paso.
    -- Con el fondo quieto, arrastrar el mapa se lee como mover una lista por
    -- encima de una pared; moviendose, se lee como avanzar por un sitio. El
    -- desfase va en enteros y en ciclos de dos bandas, que es lo que mantiene
    -- el damero del mismo lado siempre.
    local desfase = math.floor(scroll * 0.25) % 192
    for k = -2, math.ceil(H / 96) do
        love.graphics.setColor(k % 2 == 0 and Palette.fondoAlt or Palette.fondo)
        love.graphics.rectangle("fill", 0, k * 96 + desfase, W, 96)
    end
    love.graphics.setColor(1, 1, 1, 1)

    local abierto = Session.desbloqueado()
    local top = Mapa.cabecera()

    -- El camino va recortado a la zona de debajo de la cabecera: sin el
    -- tijeretazo, un nodo a medio subir se dibuja encima del titulo.
    love.graphics.setScissor(0, top, W, H - top)

    -- El reguero ENTERO antes que los nodos: un nodo tiene que tapar las
    -- migas que le llegan, no al reves.
    for n = 1, Levels.total - 1 do
        for _, f in ipairs(MIGAS) do
            local t = n + f
            local y = top + caminoY(t) + scroll
            if y > top - 20 and y < H + 20 then
                -- El tramo ya andado va de miga y el que falta de linea
                -- apagada: es lo que hace que el camino cuente por si solo
                -- hasta donde has llegado, sin un numero que lo diga.
                local x = caminoX(t)
                UI.discoPixel(x, y, 2, Palette.ink, U)
                UI.discoPixel(x, y, 1, t < abierto and Palette.miga or Palette.uiLine, U)
            end
        end
    end

    -- Donde se para el perro. Se apunta en la vuelta y se pinta DESPUES de
    -- todos los nodos: la cara mide noventa y seis y el camino sube de ciento
    -- cuarenta en ciento cuarenta, asi que en los tramos donde la ese va casi
    -- recta el nodo de arriba se dibujaba encima de una oreja. Delante no tapa
    -- nada que haga falta -- lo que hay encima del nodo que toca esta cerrado.
    local parado = nil

    for n = 1, Levels.total do
        local x, y = caminoX(n), top + caminoY(n) + scroll
        if y > top - 120 and y < H + 120 then
            -- Un nivel se abre al SOLTAR encima y solo si el dedo no ha
            -- arrastrado: si no, mover el camino abriria el nodo que quedara
            -- debajo del pulgar. Lo mira `nodo`, que es quien tiene el
            -- rectangulo con el que se hunde: preguntado aqui por separado
            -- serian dos rectangulos que se pueden separar, y entonces habria
            -- un nodo que se hunde y otro que se abre.
            local tocado, caida = nodo(n, x, y, abierto, not tragarToque)
            -- El perro baja con la ficha en la que esta parado: quieto encima
            -- de un nodo que se hunde se queda flotando en el aire.
            if n == abierto then parado = { x, y + caida * U } end
            if tocado then
                Sfx.play("toque", 1.4)
                ScreenManager.switch("juego", n)
            end
        end
    end

    if parado then kiko(parado[1], parado[2]) end
    love.graphics.setScissor()

    -- Cabecera encima del camino.
    UI.rect(0, 0, W, top - 8, Palette.mix(Palette.ink, Palette.uiBack, 0.5))
    UI.textoCentro("KIKO", W / 2, Constants.SAFE_TOP + 8, Palette.gold, Fonts.huge)

    local s = 2
    local ew = select(1, Art.size("estrella")) * s
    local texto = string.format("%d / %d", Session.totalEstrellas(), Levels.total * 3)
    local ancho = ew + 8 + Fonts.small:getWidth(texto)
    local ex = W / 2 - ancho / 2
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Art.get("estrella"), math.floor(ex),
                       math.floor(top - 46), 0, s, s)
    UI.texto(texto, ex + ew + 8, top - 44, Palette.text, Fonts.small)

    -- El sonido, en la esquina. Es el unico ajuste que tiene el juego.
    --
    -- En MAYUSCULAS y con la letra de un boton (`small`): un boton de 48
    -- pixeles de alto con una etiqueta de dieciseis en caja baja tiene la
    -- palabra flotando en medio de su propia cara, y lo que se lee no es un
    -- ajuste secundario, es un boton al que le sobra sitio. Los dos botones
    -- grandes de la portada se quedan en caja baja: ahi la letra mide 48 y las
    -- mayusculas no anaden nada que no traiga ya el tamano.
    local bw, bh = 120, 48
    if UI.boton(W - bw - 14, Constants.SAFE_TOP + 12, bw, bh,
                Sfx.activo and "SONIDO" or "MUDO",
                { tono = Sfx.activo and Palette.green or Palette.uiLine, font = Fonts.small }) then
        Sfx.silenciar(Sfx.activo)
        Session.datos.sonido = Sfx.activo
        Session.save()
    end

    -- Y la vuelta a la portada, en la otra esquina. Sin boton, la unica salida
    -- del mapa en un movil es el gesto de atras del sistema, que en LÖVE no
    -- llega.
    if UI.boton(14, Constants.SAFE_TOP + 12, bw, bh, "ATRAS",
                { tono = Palette.uiLine, font = Fonts.small }) then
        Sfx.play("toque", 1.2)
        ScreenManager.switch("portada")
    end
end

return Mapa
