-- La cabecera: Kiko, su barra de hambre, los movimientos y el objetivo.
--
-- Se dibuja en VIRTUAL, encima del tablero, y no sabe nada de como va la
-- partida: se le pasa el estado y lo pinta. Es lo que permite que cualquier
-- otra pantalla dibuje la misma barra sin duplicar una linea.
--
-- El reparto son DOS FRANJAS y no dos columnas. Arriba, en una sola linea, lo
-- que cambia con cada jugada: la cara de Kiko, a su derecha los movimientos que
-- quedan y en el canto opuesto los puntos, los dos numeros del mismo cuerpo y a
-- la misma altura -- lo que queda y lo que llevas, uno en cada punta. Debajo, la
-- barra de hambre cruzando la pantalla ENTERA, y colgando de ella el objetivo.
--
-- La barra manda por ancho y no por posicion: es lo unico de la cabecera que se
-- mide de un canto a otro, y una barra que cruza la pantalla se lee de un
-- vistazo hasta donde llega. Debajo del perro y no al lado sigue diciendo lo
-- mismo -- una barra de progreso dice cuanto llevas, una barra debajo de un
-- perro dice cuanto le falta por comer -- sin partir la cabecera en dos mitades
-- que se leen como dos cosas apiladas.
--
-- Lo unico que la cabecera pregunta fuera de lo que se le pasa es DONDE
-- empieza el bol (`Constants.boardOrigin`), y es para no pintar encima de el:
-- el alto del lienzo cambia con la pantalla y el del tablero no, asi que el
-- hueco que hay hasta el acero va de cien pixeles en un movil largo a ninguno
-- en un 9:16 pelado. Ver `sitio()`.

local Constants = require("src.constants")
local Palette   = require("src.palette")
local UI        = require("src.ui")
local Art       = require("src.art")

local Hud = {}

-- La barra esta dibujada como un sprite mas, y su pixel es EL PIXEL DEL ARTE
-- (`Constants.ART` virtuales). No es un numero elegido: es el mismo pixel que
-- miden las galletas que hay justo debajo, y es lo que hace que la cabecera se
-- lea como parte del juego en vez de como un widget puesto encima. Como ART
-- baja de escalon en pantallas estrechas, esto es una funcion y no una
-- constante.
local function pixel() return Constants.ART end

-- Siete pixeles gordos de alto -- veintiocho virtuales a escala cuatro. El
-- motivo de que no sea menos es el de siempre: las estrellas de los umbrales
-- van DENTRO (ver abajo) y miden seis pixeles gordos; con la barra mas fina
-- sobresalen por los dos cantos y entonces no marcan un punto de la barra,
-- flotan encima de ella.
local function altoBarra() return 7 * pixel() end

-- Lo que el bloque del objetivo se mete por dentro del canto DERECHO de la
-- barra. El objetivo CUELGA de la barra -- es lo que la barra esta contando --
-- y a ras con ella las dos cosas se leen como dos filas sueltas de una lista
-- en vez de como una cosa y su detalle. Cuatro pixeles gordos y no dos porque
-- la barra cruza la pantalla entera: contra algo tan largo, una sangria corta
-- no se lee como sangria, se lee como un icono mal puesto.
local function sangria() return 4 * pixel() end

-- El margen de la pantalla -- lo que la barra deja a cada lado -- y el hueco
-- entre las cosas de la linea de arriba.
local MARGEN = 18
local HUECO  = 12

--== La barra de hambre ====================================================

-- Los tres umbrales se marcan CON SU ESTRELLA sobre la barra, no con una raya:
-- una raya dice que hay un hito, la estrella dice cual es y si ya lo tienes.
-- Van DENTRO de la barra y no encima porque encima chocaban con la cifra de
-- puntos, y la cifra no se puede mover: es lo segundo que mas se mira de la
-- pantalla.
--
-- Un nivel SIN umbrales -- una ronda de arcade, donde no hay estrellas que
-- sacar sino una meta que pasar -- llena la barra contra su meta y no marca
-- nada. Es la misma barra y hace lo mismo: decir cuanto falta para que Kiko
-- deje de tener hambre. Lo que cambia es que ahi llenarla es ganar.
function Hud.barra(x, y, w, nivel, puntos)
    local u = pixel()
    local h = altoBarra()
    local hitos = nivel.estrellas
    local maximo = hitos and hitos[3] or nivel.objetivo.meta
    local lleno = math.min(1, puntos / maximo)
    local hecho = puntos >= maximo

    -- Verde al llegar al ultimo umbral -- ya no queda hambre que llenar -- y los
    -- tres tonos cambian a la vez: un relleno verde con la luz dorada encima no
    -- se lee como un cambio de color, se lee como un fallo de dibujo.
    UI.barraPixel(x, y, w, h, u, lleno, {
        borde  = Palette.uiLine,
        hueco  = Palette.uiBack,
        base   = hecho and Palette.green     or Palette.gold,
        luz    = hecho and Palette.greenLite or Palette.goldLite,
        sombra = hecho and Palette.greenDark or Palette.goldDark,
    })

    for _, umbral in ipairs(hitos or {}) do
        local id = puntos >= umbral and "estrella" or "estrellaOff"
        -- La estrella va a media escala de arte: entera no cabe dentro de la
        -- barra, y sacarla fuera es justo lo que se evito poniendolas dentro.
        local s = math.max(1, math.floor(u / 2))
        local ew = select(1, Art.size(id)) * s
        -- La ultima estrella se apoya en el canto derecho en vez de salirse
        -- por el: esta en el 100% de la barra, y centrada ahi se sale media.
        local ex = x + w * (umbral / maximo) - ew / 2
        ex = math.min(ex, x + w - ew)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Art.get(id), math.floor(ex), math.floor(y + h / 2 - ew / 2), 0, s, s)
    end
end

--== El objetivo ===========================================================

-- La linea alta del objetivo: el icono de lo que se pide y el contador.
-- `progreso` lo calcula la pantalla de juego, que es la unica que sabe lo que
-- lleva roto.
--
-- Va pegado al canto DERECHO de la barra, sangrado por dentro (ver `sangria`) y
-- no centrado ni a la izquierda: cuelga de la barra, que es lo que la barra
-- esta contando, y en el canto derecho no compite con la cara del perro -- lo
-- unico que hay encima suyo es donde acaba la barra.
--
-- Para poder pegarlo a la derecha hay que MEDIRLO antes de dibujarlo, asi que
-- primero se arma la lista de lo que se pide y luego se pinta: es tambien lo
-- que deja que el objetivo de dos colores y el "de mas" del arcade sean filas
-- de la misma lista en vez de ramas con su propio dibujado.
--
-- Cada pieza se mide por los PIXELES QUE SE VEN del icono: cada silueta deja un
-- margen transparente distinto por su izquierda (`Art.margenIzq`) y sin
-- restarlo el bloque baila un pixel o dos segun el nivel.
--
-- El alto es fijo -- el de la galleta, que es el icono mas alto de los
-- cuatro -- y es lo ultimo que mide la cabecera: un objetivo de puntos y uno
-- de recoger tienen iconos de distinto tamano, y con el alto al aire el
-- tablero subiria y bajaria un par de pixeles de un nivel a otro.
local ALTO_OBJETIVO = Constants.TILE * 2

-- El aire entre una pieza y la siguiente.
local HUECO_PIEZA = 20

-- Lo que pide el nivel, en orden y ya resuelto contra el progreso: cada pieza
-- es un icono, su cifra y su color. El objetivo de MAS (las rondas glotonas del
-- arcade) va detras del principal y en la misma linea: son dos cosas que hay
-- que hacer en la misma ronda, y en dos lineas se leerian como que una
-- sustituye a la otra.
local function piezasObjetivo(nivel, progreso, puntos)
    local o = nivel.objetivo
    local l = {}

    local function pon(id, texto, color)
        l[#l + 1] = { id = id, texto = texto, color = color or Palette.text }
    end

    if o.tipo == "puntos" then
        -- La misma cifra que la barra y que el marcador: son tres sitios
        -- contando lo mismo en la misma pantalla, y si uno va rodando y otro
        -- ya esta puesto, lo que se lee no es una cuenta, es un descuadre.
        pon("estrella", string.format("%d / %d", math.min(puntos, o.meta), o.meta))
    elseif o.tipo == "barro" then
        -- El barro cuenta HACIA ABAJO y por eso lleva la palabra: un numero
        -- suelto al lado de un icono se lee como "llevas tantos", y aqui es al
        -- reves -- son los que faltan.
        pon("barro1", string.format("quedan %d", progreso.barro))
    elseif o.tipo == "pastillas" then
        pon("pastilla", string.format("%d / %d", progreso.pastillas, o.n))
    elseif o.tipo == "recoger" then
        for _, pide in ipairs(o.lista) do
            local hechos = math.min(progreso.recogidos[pide.color] or 0, pide.n)
            pon(Art.idGalleta(pide.color), string.format("%d/%d", hechos, pide.n),
                hechos >= pide.n and Palette.green or Palette.text)
        end
    end

    -- El barro y el hielo de los extras cuentan HACIA ABAJO -- son los que
    -- quedan -- y por eso van en verde solo al llegar a cero. Es la misma
    -- cuenta que lleva el objetivo de barro de la campana, con el mismo icono.
    for _, e in ipairs(nivel.extra or {}) do
        if e.tipo == "pastillas" then
            local hechas = math.min(progreso.pastillas, e.n)
            pon("pastilla", string.format("%d/%d", hechas, e.n),
                hechas >= e.n and Palette.green or Palette.text)
        elseif e.tipo == "barro" then
            pon("barro1", tostring(progreso.barro),
                progreso.barro == 0 and Palette.green or Palette.text)
        elseif e.tipo == "hielo" then
            pon("hielo", tostring(progreso.hielo or 0),
                (progreso.hielo or 0) == 0 and Palette.green or Palette.text)
        elseif e.tipo == "moho" then
            -- El unico numero de la cabecera que puede SUBIR sin que el
            -- jugador haga nada. Cuenta hacia abajo como el barro y el hielo,
            -- pero es el que hay que mirar dos veces, que es justo lo que se
            -- quiere de el.
            pon("moho", tostring(progreso.moho or 0),
                (progreso.moho or 0) == 0 and Palette.green or Palette.text)
        end
    end

    return l
end

-- `derecha` es donde acaba el bloque, no donde empieza. `puntos` es la cifra
-- que se esta pintando ahora mismo (ver `Hud.draw`); sin ella, la de verdad.
function Hud.objetivo(derecha, y, nivel, progreso, puntos)
    local escala = 2
    local lista = piezasObjetivo(nivel, progreso, puntos or progreso.puntos)

    local total = 0
    for i, p in ipairs(lista) do
        local iw = select(1, Art.size(p.id))
        p.margen = Art.margenIzq(p.id) * escala
        p.hueco  = (iw * escala - p.margen) + 6      -- del primer pixel visible a la cifra
        p.ancho  = p.hueco + Fonts.small:getWidth(p.texto)
        total = total + p.ancho + (i > 1 and HUECO_PIEZA or 0)
    end

    local px = derecha - total
    local yTexto = y + (ALTO_OBJETIVO - Fonts.small:getHeight()) / 2

    for i, p in ipairs(lista) do
        if i > 1 then px = px + HUECO_PIEZA end
        local ih = select(2, Art.size(p.id))
        -- El sprite se dibuja corrido a la izquierda lo que mida su margen en
        -- blanco: lo que cae en `px` es el primer pixel que se ve.
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Art.get(p.id), math.floor(px - p.margen),
                           math.floor(y + (ALTO_OBJETIVO - ih * escala) / 2), 0, escala, escala)
        UI.texto(p.texto, px + p.hueco, yTexto, p.color, Fonts.small)
        px = px + p.ancho
    end
end

--== La cabecera entera ====================================================

-- Lo que la cabecera pega arriba: el margen contra el canto, el hueco bajo el
-- nombre de la ronda y el que la barra deja antes del objetivo.
local ARRIBA       = 8
local HUECO_NOMBRE = 6
local HUECO_OBJ    = 8

-- El aire entre el bloque del perro y la barra. Es lo unico de la cabecera
-- que ESTIRA: lo que sobra hasta el bol se reparte aqui en vez de quedarse
-- muerto entre el objetivo y el acero. Con topes por los dos lados -- por
-- debajo del minimo la barra se pega a la barbilla de Kiko, y por encima del
-- maximo deja de leerse como la barra DE ese bloque y pasa a ser una fila
-- suelta.
local AIRE_MIN, AIRE_MAX = 10, 36

-- Tres pixeles gordos de respiro contra el acero -- gordos y no virtuales, como
-- todo lo que se mide contra el bol. La cabecera puede llegar hasta el, pero a
-- ras del acero el objetivo ya no cuelga de la barra: parece apoyado en el
-- canto del cuenco.
local function respiro() return 3 * pixel() end

-- El sitio que tiene la cabecera, del canto de arriba al bol. El bol empieza
-- cinco pixeles de arte por encima de la primera fila (ver `dibujarTablero`
-- en juego.lua), y de ahi para arriba no hay nada mas.
local function sitio()
    local _, oy = Constants.boardOrigin()
    return (oy - 5) * Constants.ART - respiro() - Constants.SAFE_TOP
end

-- Lo que ocuparia la cabecera con una cara de `kh` de alto y `aire` debajo.
-- Se mide ANTES de pintar nada porque de esa cuenta salen las dos cosas que
-- se adaptan: si el perro cabe un escalon mas grande y cuanto baja la barra.
local function altoCabecera(kh, aire)
    return ARRIBA + Fonts.small:getHeight() + HUECO_NOMBRE + kh + aire
           + altoBarra() + HUECO_OBJ + ALTO_OBJETIVO
end

-- `marcador` es la cifra de puntos ya resuelta para pintarla: la que se ve
-- (que va rodando detras de la de verdad), lo que hay que hincharla y de que
-- color. La trae hecha `Efectos.cuenta()` y la cabecera no sabe que hay una
-- cuenta en marcha -- aqui no se decide nada, como en todo este archivo. Sin
-- ella se pinta `progreso.puntos` pelado, que es lo que hacia antes y lo que
-- hace cualquier pantalla que no anime nada.
--
-- `perro` es lo mismo con la cara: llega con el animo ya elegido y la cabecera
-- solo pregunta que fotograma toca (`src/kiko.lua`). Que la cabecera no sepa
-- por que el perro bosteza es lo que deja que el cartel del final ensene EL
-- MISMO perro sin repetir la cuenta.
--
-- Devuelve la altura que ha ocupado, por si alguien necesita saber donde
-- acaba.
function Hud.draw(nivel, numero, progreso, movimientos, marcador, perro)
    local W = Constants.GAME_WIDTH
    local y = Constants.SAFE_TOP + ARRIBA

    -- Por donde va la partida, arriba del todo y en pequeno: es lo que menos
    -- cambia de la pantalla y lo unico que no hay que volver a mirar una vez
    -- empezada. Nivel o ronda segun el modo, y el modo lo dice la marca que
    -- trae el propio nivel -- NO si tiene nombre, que es como se preguntaba
    -- antes: los niveles de la campana siguen teniendo uno en `Levels.lista`,
    -- pero es una etiqueta interna y no se ensena, asi que preguntar por el
    -- seria preguntar por una cosa para averiguar otra.
    UI.textoCentro(string.format(nivel.arcade and "Ronda %d" or "Nivel %d", numero),
                   W / 2, y, Palette.dim, Fonts.small)
    y = y + Fonts.small:getHeight() + HUECO_NOMBRE

    -- Kiko, a escala de arte y sin excepciones: su pixel mide lo que el de las
    -- galletas que hay justo debajo, y es lo que hace que la cabecera se lea
    -- como parte del juego en vez de como un widget puesto encima.
    --
    -- Antes crecia un escalon cuando la pantalla daba de si, y ya no: aquella
    -- cara media veinticuatro pixeles de arte y a escala de tablero se quedaba
    -- pequena al lado de los dos numeros. La de la hoja mide TREINTA Y DOS, asi
    -- que a escala de tablero ya ocupa mas que el perro crecido de entonces --
    -- y el escalon de mas dejaba al perro con un pixel distinto del de las
    -- galletas, que era el precio que habia que pagar por el.
    local escala = Constants.ART
    local kw, kh = Art.size(perro:id())
    kw, kh = kw * escala, kh * escala

    perro:dibujar(MARGEN, y, escala)

    -- Los movimientos, a la derecha de la cara y centrados contra ella. Es el
    -- numero que mas se mira y el unico que se pone rojo: por debajo de cinco,
    -- el nivel ha cambiado de genero y hay que enterarse sin leer.
    --
    -- La cifra va encima de la palabra y no debajo porque lo que cambia es la
    -- cifra, y la palabra es "MOV." y no "MOVIMIENTOS" porque ahora comparte
    -- linea con los puntos: la palabra entera empujaba la cifra hacia el centro
    -- de la pantalla y los dos numeros dejaban de estar cada uno en su punta.
    local altoMov = Fonts.huge:getHeight() - 4 + Fonts.tiny:getHeight()
    local yMov = y + math.floor((kh - altoMov) / 2)
    -- El hueco entre la cara y la cifra es doble: las orejas de Kiko llegan casi
    -- al canto del sprite y con el hueco de siempre la cifra se le pega a la
    -- oreja derecha, que es justo la que se sale.
    local xMov = MARGEN + kw + HUECO * 2
    local cxMov = xMov + math.max(Fonts.huge:getWidth(tostring(movimientos)),
                                  Fonts.tiny:getWidth("MOV.")) / 2

    UI.textoCentro(tostring(movimientos), cxMov, yMov,
                   movimientos <= 5 and Palette.red or Palette.text, Fonts.huge)
    UI.textoCentro("MOV.", cxMov, yMov + Fonts.huge:getHeight() - 4,
                   Palette.dim, Fonts.tiny)

    -- Los puntos, en el canto de enfrente y a cuerpo GIGANTE -- un tercio mas
    -- que los movimientos, que ya van a cuerpo HUGE. Son el numero que se
    -- mira al terminar una jugada, y es el unico sitio de la pantalla que
    -- puede permitirse ese tamano: no tiene nada al lado con lo que chocar
    -- hasta el canto. No llevan palabra debajo porque la barra que viene
    -- justo despues ya dice lo que cuentan.
    --
    -- Van centrados contra la cara igual que los movimientos, y no alineados
    -- por arriba con ellos: con dos cuerpos tan distintos, lo que empareja los
    -- dos numeros es el centro, no el borde de arriba de la letra.
    --
    -- Y el ACHUCHON al cobrar: la cifra se hincha y vuelve. Crece desde el
    -- canto DERECHO y desde la mitad de la letra -- centrada creceria hacia
    -- fuera de la pantalla, y anclada arriba daria un brinco hacia abajo en
    -- vez de hincharse. A escala 1 lo que se dibuja es exactamente lo de
    -- antes: el `scale` solo existe mientras dura el golpe.
    local puntos = marcador and marcador.puntos or progreso.puntos
    local hg = Fonts.giant:getHeight()
    local yPuntos = y + math.floor((kh - hg) / 2)
    -- Donde queda la cifra, para que el total de una jugada del arcade sepa a
    -- donde volar (`src/pizarra.lua`): el canto derecho y la mitad de la letra.
    Hud.puntosX, Hud.puntosY = W - MARGEN, math.floor(yPuntos + hg / 2)
    love.graphics.push()
    love.graphics.translate(W - MARGEN, math.floor(yPuntos + hg / 2))
    love.graphics.scale(marcador and marcador.escala or 1)
    UI.textoDerecha(tostring(puntos), 0, math.floor(-hg / 2),
                    marcador and marcador.color or Palette.text, Fonts.giant)
    love.graphics.pop()

    -- La barra, de canto a canto y debajo de todo el bloque del perro. Se
    -- llena contra la MISMA cifra que se acaba de pintar y no contra la de
    -- verdad: con la cifra rodando y la barra ya puesta en su sitio, la barra
    -- llegaria al umbral antes que el numero y la estrella se encenderia sin
    -- que nada la hubiera alcanzado todavia.
    -- Lo que sobre hasta el bol se lo queda este hueco, con sus topes: es el
    -- unico sitio de la cabecera donde un pixel de mas no descoloca nada.
    local aire = math.max(AIRE_MIN, math.min(AIRE_MAX, sitio() - altoCabecera(kh, 0)))
    local yBarra = y + kh + aire
    Hud.barra(MARGEN, yBarra, W - 2 * MARGEN, nivel, puntos)

    -- Y colgando de ella el objetivo, pegado por dentro de su canto DERECHO.
    -- Aqui se acaba la cabecera: la frase con todas las letras se fue, porque
    -- el icono con su cifra ya lo dice y la frase era la unica linea que no
    -- cambiaba en toda la partida.
    local yObj = yBarra + altoBarra() + HUECO_OBJ
    Hud.objetivo(W - MARGEN - sangria(), yObj, nivel, progreso, puntos)

    return yObj + ALTO_OBJETIVO
end

return Hud
