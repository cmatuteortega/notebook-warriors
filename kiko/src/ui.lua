-- Interfaz inmediata.
--
-- No hay objetos ni arboles de widgets: cada pantalla dibuja sus botones cada
-- fotograma y `UI.boton` devuelve true si el toque de este fotograma cayo
-- dentro. Un panel entero son diez lineas y no hay estado que sincronizar
-- entre lo que se ve y lo que responde.
--
-- El puntero lo alimenta main.lua en coordenadas VIRTUALES. La interfaz no
-- vive en espacio de arte: el texto es una fuente TTF y necesita la
-- resolucion fina.

local Constants = require("src.constants")
local Palette   = require("src.palette")

local UI = {}

UI.pointer = { x = -1000, y = -1000, down = false, released = false, moved = false }
UI.locked = false

function UI.press(x, y)
    UI.pointer.x, UI.pointer.y = x, y
    UI.pointer.down = true
    UI.pointer.moved = false
    UI.pointer.startX, UI.pointer.startY = x, y
end

function UI.move(x, y)
    UI.pointer.x, UI.pointer.y = x, y
    if UI.pointer.down and UI.pointer.startX then
        local dx, dy = x - UI.pointer.startX, y - UI.pointer.startY
        if dx * dx + dy * dy > 144 then UI.pointer.moved = true end
    end
end

function UI.release(x, y)
    UI.pointer.x, UI.pointer.y = x, y
    UI.pointer.down = false
    -- Un arrastre no es un toque: soltar lejos de donde se apreto no dispara
    -- botones. Es lo que deja convivir el arrastre del tablero con la
    -- botonera de abajo.
    UI.pointer.released = not UI.pointer.moved
end

-- Al final de cada draw: consume el toque del fotograma.
function UI.finish()
    UI.pointer.released = false
    UI.locked = false
end

function UI.lock(v) UI.locked = v and true or false end

function UI.dentro(x, y, w, h)
    local p = UI.pointer
    return p.x >= x and p.y >= y and p.x < x + w and p.y < y + h
end

--== Primitivas ============================================================

function UI.rect(x, y, w, h, color)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), math.floor(w), math.floor(h))
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.borde(x, y, w, h, color, grosor)
    love.graphics.setColor(color)
    love.graphics.setLineWidth(grosor or 3)
    love.graphics.rectangle("line", math.floor(x) + 1, math.floor(y) + 1,
                            math.floor(w) - 2, math.floor(h) - 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Un rectangulo de esquinas COMIDAS, dibujado en pixeles GORDOS de lado `u`.
--
-- La esquina no se redondea con una curva: se le quita un escalon de dos
-- pixeles y otro de uno, que es como se redondea una esquina cuando el pixel
-- se ve. Una curva de verdad -- un `rectangle` con radio -- a este tamano son
-- cuatro pixeles borrosos por canto, y ahi se acaba de golpe la ilusion de que
-- el juego esta dibujado pixel a pixel.
--
-- `ancho` (opcional) pinta solo los primeros N pixeles virtuales contados
-- desde la izquierda: es lo que deja que el relleno de una barra conserve su
-- canto izquierdo redondeado y corte a plomo por donde va. Cortar con un
-- scissor haria lo mismo, pero el scissor vive en coordenadas de ventana y
-- esto se dibuja dentro del lienzo virtual.
--
-- Los escalones van de fuera hacia dentro y en pixeles gordos: la primera fila
-- se mete dos, la segunda uno, y el resto es recto.
--
-- Hay DOS esquinas y no una. `FUERA` es la silueta; `DENTRO` es esa misma
-- esquina un pixel gordo por dentro, que no es la de fuera repetida: al bajar
-- una fila y meterse un pixel, la escalera pierde su primer escalon. Dibujar
-- el hueco de una barra con la esquina de fuera engorda el canto justo en las
-- puntas y los dos extremos dejan de leerse redondos para leerse en punta.
UI.ESQUINA        = { 2, 1 }
UI.ESQUINA_DENTRO = { 1 }

function UI.rectPixel(x, y, w, h, color, u, ancho, esquina)
    esquina = esquina or UI.ESQUINA
    u = math.max(1, math.floor(u or 2))
    x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
    ancho = math.floor(ancho or w)
    if w <= 0 or h <= 0 or ancho <= 0 then return end

    -- En una barra baja no caben todos los escalones. Se pierde el de fuera
    -- antes que el de dentro: quitando el de dentro la esquina deja de ser una
    -- escalera y vuelve a ser un corte a bisel.
    local n = math.min(#esquina, math.floor(h / (2 * u)))
    local salto = #esquina - n

    love.graphics.setColor(color)
    local cuerpo = h - 2 * n * u
    if cuerpo > 0 then
        love.graphics.rectangle("fill", x, y + n * u, math.min(w, ancho), cuerpo)
    end
    for i = 1, n do
        local dx = esquina[i + salto] * u
        local tw = math.min(w - 2 * dx, ancho - dx)
        if tw > 0 then
            love.graphics.rectangle("fill", x + dx, y + (i - 1) * u, tw, u)
            love.graphics.rectangle("fill", x + dx, y + h - i * u, tw, u)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Una barra de progreso de pixeles gordos: el canto, el hueco y el relleno con
-- luz arriba y sombra abajo. La barra de hambre de la cabecera y la de la carga
-- son la misma barra y esta es la razon de que lo sigan siendo.
--
-- `colores` lleva { borde, hueco, base, luz, sombra }; luz y sombra pueden
-- faltar. Quien quiera pintar algo encima -- las estrellas de los umbrales --
-- lo hace despues: aqui no se dibuja nada que no sea la barra.
function UI.barraPixel(x, y, w, h, u, lleno, colores)
    UI.rectPixel(x, y, w, h, colores.borde, u)

    local ix, iy = x + u, y + u
    local iw, ih = w - 2 * u, h - 2 * u
    UI.rectPixel(ix, iy, iw, ih, colores.hueco, u, nil, UI.ESQUINA_DENTRO)

    -- El relleno avanza de pixel gordo en pixel gordo y no en continuo: medio
    -- pixel de relleno es una columna a medio camino entre el oro y el hueco,
    -- y seria el unico color interpolado de toda la pantalla.
    local ancho = math.floor(iw * math.min(1, math.max(0, lleno)) / u) * u
    if ancho <= 0 then return end

    UI.rectPixel(ix, iy, iw, ih, colores.base, u, ancho, UI.ESQUINA_DENTRO)

    -- La luz y la sombra van por dentro de lo que se come la esquina, una fila
    -- de pixeles gordos cada una. Es lo mismo que lleva cada galleta del
    -- tablero y es lo que le da bulto a una barra plana.
    local dx = UI.ESQUINA_DENTRO[1] * u
    local fw = math.min(iw - 2 * dx, ancho - dx)
    if fw > 0 then
        if colores.luz    then UI.rect(ix + dx, iy, fw, u, colores.luz) end
        if colores.sombra then UI.rect(ix + dx, iy + ih - u, fw, u, colores.sombra) end
    end
end

-- Un disco de pixeles GORDOS de lado `u`, con el radio `R` medido tambien en
-- pixeles gordos. Es el hermano redondo de `rectPixel` y esta aqui por lo
-- mismo: un `circle` de LÖVE a este tamano es un canto suavizado, y un canto
-- suavizado en medio de un juego de pixeles no se lee como un circulo mejor,
-- se lee como un elemento pegado de otro programa.
--
-- El centro se ENGANCHA a la rejilla gorda antes de dibujar. Sin eso, dos
-- nodos del mapa a la misma altura salen con la fila de arriba en sitios
-- distintos y el camino se ve temblar al arrastrarlo.
local anchos = {}

local function filasDisco(R)
    local t = anchos[R]
    if t then return t end
    -- La anchura de cada fila, medida en el CENTRO de la fila (de ahi el 0,5):
    -- medida en el canto, el disco sale con un escalon de mas arriba y abajo y
    -- deja de leerse redondo para leerse como un octogono.
    t = {}
    for j = -R, R - 1 do
        local dy = j + 0.5
        t[#t + 1] = math.floor(math.sqrt(math.max(0, R * R - dy * dy)) + 0.5)
    end
    anchos[R] = t
    return t
end

local function rejilla(cx, cy, u)
    return math.floor(cx / u + 0.5) * u, math.floor(cy / u + 0.5) * u
end

function UI.discoPixel(cx, cy, R, color, u)
    u = math.max(1, math.floor(u or 2))
    R = math.max(1, math.floor(R))
    local x0, y0 = rejilla(cx, cy, u)
    love.graphics.setColor(color)
    for i, hw in ipairs(filasDisco(R)) do
        if hw > 0 then
            love.graphics.rectangle("fill", x0 - hw * u, y0 + (i - 1 - R) * u, hw * 2 * u, u)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- La ficha del mapa: un disco con canto, luz arriba, sombra abajo y un brillo
-- corto en el hombro izquierdo. Es la MISMA receta que `barraPixel` y que cada
-- galleta del tablero, y por eso un nodo del mapa se ve de la misma hornada que
-- el juego aunque no sea una galleta.
--
-- `colores` lleva { borde, base, luz, sombra, brillo }; los tres ultimos
-- pueden faltar y entonces la ficha sale plana, que es lo que quiere un nodo
-- apagado.
function UI.fichaPixel(cx, cy, R, u, colores)
    u = math.max(1, math.floor(u or 2))
    R = math.max(2, math.floor(R))
    UI.discoPixel(cx, cy, R, colores.borde, u)

    local x0, y0 = rejilla(cx, cy, u)
    local filas = filasDisco(R - 1)
    for i, hw in ipairs(filas) do
        local c = colores.base
        if i == 1 then c = colores.luz or colores.base
        elseif i == #filas then c = colores.sombra or colores.base end
        if hw > 0 then
            love.graphics.setColor(c)
            love.graphics.rectangle("fill", x0 - hw * u, y0 + (i - R) * u, hw * 2 * u, u)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- El brillo va PEGADO al canto de su fila, no flotando por dentro: en una
    -- esfera la luz nace en el borde, y metido un pixel hacia el centro se lee
    -- como una mancha y no como un reflejo. Dos pixeles gordos de largo, que a
    -- este tamano es lo que separa un reflejo de una raya.
    if colores.brillo and #filas >= 4 then
        love.graphics.setColor(colores.brillo)
        love.graphics.rectangle("fill", x0 - filas[3] * u, y0 + (3 - R) * u, 2 * u, u)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function UI.panel(x, y, w, h, color)
    UI.rect(x, y, w, h, color or Palette.uiPanel)
    UI.borde(x, y, w, h, Palette.uiLine)
end

-- Todo el texto del juego lleva sombra de dos pixeles. No es adorno: separa
-- la letra del panel y del mantel, que son dos cremas parecidas, y sin ella el
-- texto dorado se pierde justo encima del dorado de la barra.
--
-- La sombra es `sombra` -- un topo calido -- y no tinta: con paneles claros y
-- letra marron, una sombra negra debajo de cada letra la engorda y a este
-- tamano de fuente eso no se lee como relieve, se lee como una letra borrosa.
function UI.texto(str, x, y, color, font)
    font = font or Fonts.small
    love.graphics.setFont(font)
    x, y = math.floor(x), math.floor(y)
    love.graphics.setColor(Palette.sombra[1], Palette.sombra[2], Palette.sombra[3], 0.55)
    love.graphics.print(str, x + 2, y + 2)
    love.graphics.setColor(color or Palette.text)
    love.graphics.print(str, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.textoCentro(str, cx, y, color, font)
    font = font or Fonts.small
    UI.texto(str, cx - font:getWidth(str) / 2, y, color, font)
end

function UI.textoDerecha(str, rx, y, color, font)
    font = font or Fonts.small
    UI.texto(str, rx - font:getWidth(str), y, color, font)
end

-- Parte un texto en las lineas que quepan en `ancho`, por palabras. Lo pide el
-- cartel del nivel perdido, que dice el objetivo entero -- y lo pide desde que
-- un nivel puede pedir DOS cosas ("limpia todo el barro y
-- dale 3 pastillas a Kiko"): a una linea, esa frase se sale del cartel por los
-- dos lados, y lo que se sale es justo la mitad que explica por que se ha
-- perdido. Parte y no encoge la letra: dos tamanos de la misma frase segun lo
-- larga que sea se leen como dos carteles distintos. Es tambien el respaldo de
-- `UI.dosLineas` para el texto que no cabe ni partido por la mitad.
function UI.lineas(str, ancho, font)
    font = font or Fonts.small
    local out, linea = {}, ""
    for palabra in str:gmatch("%S+") do
        local prueba = (linea == "" and palabra) or (linea .. " " .. palabra)
        if linea ~= "" and font:getWidth(prueba) > ancho then
            out[#out + 1] = linea
            linea = palabra
        else
            linea = prueba
        end
    end
    if linea ~= "" then out[#out + 1] = linea end
    return out
end

-- Parte un texto en DOS lineas lo mas PAREJAS que pueda, o lo deja en una si
-- cabe entero. No es lo que hace `UI.lineas`, que llena cada linea hasta el
-- borde y deja sola a la ultima palabra: "+300 POR CADA CUATRO EN / LINEA" se
-- lee como una frase cortada y "+300 POR CADA / CUATRO EN LINEA" se lee como
-- dos lineas. La diferencia importa en la carta de mejora porque ahi la viuda
-- no seria la excepcion: con la letra en caja alta NINGUNO de los textos cabe
-- de una linea, asi que el corte feo seria el aspecto normal de la pantalla.
function UI.dosLineas(str, ancho, font)
    font = font or Fonts.small
    if font:getWidth(str) <= ancho then return { str } end

    local palabras = {}
    for palabra in str:gmatch("%S+") do palabras[#palabras + 1] = palabra end

    local corte, mejor
    for k = 1, #palabras - 1 do
        -- Lo que se busca es que la linea MAS LARGA sea lo mas corta posible:
        -- es lo unico que se ve, porque el bloque se lee por su canto derecho.
        local largo = math.max(font:getWidth(table.concat(palabras, " ", 1, k)),
                               font:getWidth(table.concat(palabras, " ", k + 1)))
        if not mejor or largo < mejor then mejor, corte = largo, k end
    end

    -- Si ni el mejor reparto cabe, manda el que no se sale: tres lineas feas se
    -- leen, y dos lineas que se salen del canto no.
    if not corte or mejor > ancho then return UI.lineas(str, ancho, font) end
    return { table.concat(palabras, " ", 1, corte),
             table.concat(palabras, " ", corte + 1) }
end

-- MAYUSCULAS de verdad, acentos incluidos. El `string.upper` de Lua va byte a
-- byte y solo sabe de ASCII, asi que "limón" sale "LIMóN" -- una minuscula
-- acentuada en medio de una palabra en caja alta, que es exactamente el
-- aspecto de un texto mal montado. Y el texto que lee el jugador SI lleva
-- acentos: es la unica letra del juego que los lleva y no se van a perder al
-- subirla de caja.
--
-- La fuente los tiene arriba tambien: se comprobo pintandolos, y la tilde de la
-- Á cae dos pixeles por encima de la caja de la A. Estas son las siete letras
-- que el castellano pone encima de una vocal; del resto se encarga `%l`, que
-- sin tocar la tabla de idioma no toca ni un byte alto.
local ALTAS = {
    ["á"] = "Á", ["é"] = "É", ["í"] = "Í", ["ó"] = "Ó", ["ú"] = "Ú",
    ["ñ"] = "Ñ", ["ü"] = "Ü",
}

function UI.mayus(str)
    local alta = str:gsub("[\194-\244][\128-\191]+", function(c) return ALTAS[c] or c end)
    return (alta:gsub("%l", string.upper))
end

function UI.icono(id, x, y, escala)
    local Art = require("src.art")
    escala = escala or Constants.ART
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Art.get(id), math.floor(x), math.floor(y), 0, escala, escala)
end

--== Lo que se aprieta =====================================================
--
-- Un boton de este juego es una GALLETA de interfaz: canto oscuro, cuerpo con
-- las esquinas comidas, una fila de luz arriba, una de sombra abajo y dos
-- brillos cortos en el canto. Es la misma receta que la barra de hambre, que
-- los nodos del mapa y que cada pieza del tablero, y por eso un boton no se
-- lee como un cuadro de dialogo puesto encima del juego.
--
-- Y tiene GROSOR: debajo de la cara hay una falda del color del canto, y lo
-- que hace el dedo es hundir la cara hasta el fondo de esa falda. Un boton
-- plano que cambia de color al tocarlo dice "me han pulsado"; uno que se
-- hunde dice "esto es un boton", que es lo que hace falta la primera vez.
--
-- Nada de esto se interpola. La cara baja y sube de PIXEL GORDO en pixel
-- gordo (`Constants.ART`, el mismo que el tablero) porque medio pixel de
-- caida a escala 4 son cuatro pixeles borrosos por canto, que es justo lo que
-- el juego entero esta puesto a evitar.
--
-- Son TRES funciones y no una, en capas, porque hay cosas que se aprietan y no
-- son botones:
--
--   `UI.pulsado`  el reloj -- caliente, tocado, y en cual de los tres sitios
--                 enteros va la cara. Lo usa cualquier forma, tambien un disco.
--   `UI.galleta`  el chasis rectangular con su falda, y el hueco de dentro.
--   `UI.boton`    el chasis con una etiqueta en medio.
--
-- Estaba todo dentro de `UI.boton` y valia mientras el boton fue lo unico que
-- se hundia. Dejo de valer con dos sitios a la vez: los nodos REDONDOS del
-- mapa, que no pueden usar el chasis pero tienen que usar el reloj, y las
-- cartas de mejora del arcade, que llevan dentro un icono, dos lineas y unos
-- puntos y no una etiqueta. Lo que las tres capas evitan es que cada una se
-- copie el hundimiento por su lado: copiado, el mapa y la botonera contestan
-- distinto al mismo dedo en cuanto se toque una de las dos.

-- El grosor de la falda y el salto del rebote, en pixeles GORDOS.
--
-- Dos de falda y no uno: con uno, la cara hundida y la cara en reposo se
-- diferencian en cuatro pixeles virtuales y el hundimiento se pierde debajo
-- del dedo, que es exactamente donde pasa. Y el rebote es UN pixel gordo por
-- encima del reposo: dos ya no se leen como un boton que vuelve, se leen como
-- un boton que salta.
--
-- La falda es publica porque hay pulsables que no son botones -- los nodos del
-- mapa -- y tienen que poner su sombra a la profundidad a la que se hunden: si
-- los dos numeros no salen del mismo sitio, la ficha se hunde por debajo de su
-- propia sombra y eso se ve como una ficha que se despega del camino.
UI.FALDA     = 2
local FALDA  = UI.FALDA
local REBOTE = 1

-- Cuanto dura el rebote de soltar, en segundos. Corto a proposito: es un
-- acuse de recibo, no una animacion, y lo normal es que la pantalla cambie
-- encima de el.
local REBOTE_T = 0.16

-- El estado vivo de cada pulsable, que es lo unico que la interfaz inmediata
-- no puede sacar del fotograma: cuanto lleva hundido y cuanto le queda de
-- rebote. La llave la pone quien lo dibuja; `edad` se pone a cero al dibujar y
-- quien no se dibuje en medio segundo -- ha cambiado la pantalla -- se tira.
-- Sin esa poda, la tabla crece con cada boton que se haya visto en toda la
-- partida.
local vivos = {}

function UI.update(dt)
    for k, b in pairs(vivos) do
        b.edad = b.edad + dt
        if b.rebote > 0 then b.rebote = math.max(0, b.rebote - dt) end
        if b.edad > 0.5 then vivos[k] = nil end
    end
end

local function estado(clave)
    local b = vivos[clave]
    if not b then
        b = { rebote = 0, edad = 0 }
        vivos[clave] = b
    end
    b.edad = 0
    return b
end

-- El reloj del hundimiento, suelto del boton.
--
-- Todo lo que el dedo hunde en este juego -- el boton, el nodo del mapa, la
-- carta de mejora del arcade -- necesita las mismas tres respuestas: si el
-- dedo esta encima AHORA, si se ha soltado dentro, y en cual de los tres
-- sitios enteros va la cara. Vivian dentro de `UI.boton`, y mientras fueron
-- solo suyas estuvo bien; en cuanto un nodo REDONDO quiso hundirse igual hubo
-- que sacarlas, porque un disco no puede usar el chasis de un boton pero si
-- tiene que usar su mismo reloj -- dos relojes copiados se separan en cuanto
-- se toca uno, y entonces el mapa y la botonera responden distinto al mismo
-- dedo.
--
-- `clave` tiene que ser unica dentro de la pantalla y la pone quien dibuja:
-- aqui no se le anade el sitio a proposito, porque el mapa se ARRASTRA y una
-- llave con la posicion dentro cambiaria cada fotograma, dejando al nodo sin
-- rebote justo cuando el camino se mueve. Quien tenga etiquetas repetibles --
-- dos botones "Mapa" en dos paneles -- se la mete el mismo (ver `UI.galleta`).
--
-- `opts.falda` es lo que se hunde, en pixeles gordos (por defecto `UI.FALDA`).
-- `opts.quieto` lo deja en reposo y SORDO: ni se hunde ni contesta, que es lo
-- que quiere algo que aun esta entrando en pantalla o que esta debajo de un
-- arrastre.
--
-- Devuelve la caida en pixeles GORDOS -- 0 en reposo, la falda hundido, menos
-- el rebote al soltar --, si esta caliente y si se ha tocado.
function UI.pulsado(clave, x, y, w, h, opts)
    opts = opts or {}
    if opts.quieto or UI.locked then return 0, false, false end

    local caliente = UI.pointer.down and UI.dentro(x, y, w, h) and not UI.pointer.moved
    -- `released` ya viene limpio de arrastres (ver `UI.release`), asi que un
    -- toque que empezo aqui y acabo tres dedos mas alla no cuenta.
    local tocado = UI.pointer.released and UI.dentro(x, y, w, h)

    local b = estado(clave)
    if tocado then b.rebote = REBOTE_T end

    local caida = 0
    if caliente then
        caida = opts.falda or FALDA
    elseif b.rebote > 0 then
        caida = -REBOTE
    end
    return caida, caliente, tocado
end

-- El CHASIS de una galleta de interfaz: el bloque del canto con su falda, la
-- cara encima con su luz, su sombra y sus dos brillos, y nada dentro.
--
-- Esta suelto porque de aqui salen dos cosas: el boton, que le pone una
-- etiqueta en medio, y la carta de mejora del arcade, que le pone un icono, un
-- nombre, una linea y sus puntos. La carta se dibujaba antes a mano, con
-- `UI.borde` -- una linea VECTORIAL de LÖVE -- y un hundimiento de dos pixeles
-- virtuales puestos a ojo, y al lado del boton de la misma pantalla se leia
-- como de otro juego. Lo que dice CLAUDE.md es que un boton sale de UNA
-- funcion; una carta que quiere ser galleta tiene que salir de esta misma y no
-- de una copia, que es lo que se separa en cuanto se toque el canto.
--
-- Devuelve si se ha tocado y el HUECO de dentro (x, y, w, h de la cara, ya
-- hundida). Quien escribe dentro lo hace contra esa `y`: asi el contenido baja
-- con la cara en vez de quedarse flotando encima del hueco.
function UI.galleta(clave, x, y, w, h, opts)
    opts = opts or {}
    local u = math.max(2, Constants.ART)
    local falda = opts.falda or FALDA
    local caraH = h - falda * u

    if opts.activo == false then
        -- Un boton apagado no tiene falda ni luz: es un hueco con el nombre
        -- dentro. Con grosor se sigue leyendo como algo que se puede pulsar, y
        -- eso es peor que no verlo -- se toca, no pasa nada, y el que juega
        -- cree que el juego no le ha oido.
        UI.rectPixel(x, y, w, caraH, Palette.uiLine, u)
        UI.rectPixel(x + u, y + u, w - 2 * u, caraH - 2 * u,
                     Palette.mix(Palette.uiBack, Palette.uiPanel, 0.5), u, nil, UI.ESQUINA_DENTRO)
        return false, x + u, y + u, w - 2 * u, caraH - 2 * u
    end

    -- La llave lleva el sitio pegado: dos botones con la misma etiqueta en dos
    -- paneles distintos existen, y con la etiqueta sola compartirian rebote.
    local caida, caliente, tocado =
        UI.pulsado(clave .. "@" .. math.floor(x) .. "," .. math.floor(y), x, y, w, h, opts)

    local tono = Palette.tono(opts.tono or Palette.gold)

    -- La cara viaja entre el reposo y el fondo de la falda, y el rebote la
    -- saca un pixel gordo por encima. Los tres sitios son enteros: no hay un
    -- entre medias que dibujar.
    local caraY = y + caida * u
    local fondo = y + h              -- la falda llega siempre hasta aqui

    -- El bloque entero -- cara y falda de una pieza -- en el color del canto.
    -- Dibujarlo de una vez y no la falda por un lado y el canto por otro es lo
    -- que hace que la esquina de abajo siga siendo la misma escalera cuando la
    -- cara se hunde: en dos piezas, el canto de la cara se come el de la falda
    -- justo en las puntas.
    UI.rectPixel(x, caraY, w, fondo - caraY, tono.canto, u)

    -- La cara. Hundida va tirada hacia su sombra: la cara de un boton pulsado
    -- esta metida en su propio hueco y ahi no le da la luz.
    local cara = caliente and Palette.mix(tono.base, tono.sombra, 0.35) or tono.base
    local ix, iy = x + u, caraY + u
    local iw, ih = w - 2 * u, caraH - 2 * u
    UI.rectPixel(ix, iy, iw, ih, cara, u, nil, UI.ESQUINA_DENTRO)

    -- La luz y la sombra, por dentro de lo que se come la esquina. Es la misma
    -- fila que lleva `barraPixel`, y esta aqui por lo mismo: una cara de un
    -- solo color es una pegatina, y con las dos filas es un objeto.
    local dx = UI.ESQUINA_DENTRO[1] * u
    local fw = iw - 2 * dx
    if fw > 0 and not caliente then
        UI.rect(ix + dx, iy, fw, u, tono.luz)
        UI.rect(ix + dx, iy + ih - u, fw, u, tono.sombra)

        -- Los dos brillos del canto de arriba: cortos, separados y siempre en
        -- el tercio izquierdo, que es de donde viene la luz en todo el juego.
        -- Uno solo y largo se lee como un bisel; estos dos se leen como un
        -- caramelo. Es el mismo reflejo que llevan el bol y la chapa.
        UI.rect(ix + dx + math.floor(fw * 0.10 / u) * u, iy, math.floor(fw * 0.16 / u) * u, u, Palette.miga)
        UI.rect(ix + dx + math.floor(fw * 0.32 / u) * u, iy, math.floor(fw * 0.06 / u) * u, u, Palette.miga)
    end

    return tocado, ix, iy, iw, ih
end

-- Devuelve true si se ha tocado. `opts.activo = false` lo apaga, `opts.tono`
-- le cambia el color (oro para lo importante, verde para confirmar, el marron
-- de las lineas para lo secundario, rojo para lo que resta).
--
-- Es el chasis con una etiqueta en medio, y nada mas: todo lo que se ve de un
-- boton -- el canto, la falda, el hundimiento, el rebote -- esta en
-- `UI.galleta` y en `UI.pulsado`.
function UI.boton(x, y, w, h, etiqueta, opts)
    opts = opts or {}
    local tocado, ix, iy, iw, ih = UI.galleta(etiqueta, x, y, w, h, opts)
    local font = opts.font or Fonts.small
    local letra = opts.activo == false and Palette.dim
                  or Palette.tono(opts.tono or Palette.gold).letra
    UI.textoCentro(etiqueta, ix + iw / 2, iy + ih / 2 - font:getHeight() / 2, letra, font)
    return tocado
end

-- Un velo sobre todo el lienzo. Es de los pocos alphas del juego y esta aqui
-- para que quien lo use no lo escriba a mano.
function UI.velo(fuerza)
    love.graphics.setColor(Palette.ink[1], Palette.ink[2], Palette.ink[3], fuerza or 0.72)
    love.graphics.rectangle("fill", 0, 0, Constants.GAME_WIDTH, Constants.GAME_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)
end

return UI
