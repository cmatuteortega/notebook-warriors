-- Registro de sprites.
--
-- Todo lo que se JUEGA se genera al arrancar: no hay un PNG por galleta que
-- mantener. Cada sprite tiene un id, un tamano en pixeles de arte y un
-- generador, y si alguna vez quieres sustituir uno por arte dibujado a mano,
-- deja el PNG en `art/` con el nombre del sprite y gana sobre el generador.
--
-- La excepcion es KIKO, y es la puerta de arriba usada a proposito: sus
-- sesenta y cuatro caras vienen dibujadas a mano en `art/kiko.png` (ver "La
-- hoja de Kiko", mas abajo). El perro dejo de ser un icono el dia que tuvo que
-- bostezar, y un bostezo no se describe con elipses.
--
-- Las seis galletas salen de la MISMA tuberia: silueta -> sombreado -> brillo
-- -> contorno. Es lo que hace que se vean de la misma hornada aunque una sea
-- un hueso y otra una huella. Lo unico que cambia entre familias son el
-- poligono y los tres colores, y por eso anadir una septima galleta es una
-- fila en `Palette.galletas` y una silueta aqui.
--
-- Los generadores son deterministas: dos ejecuciones dan los mismos pixeles.
-- Nada de love.math.random aqui dentro.

local Constants = require("src.constants")
local Palette   = require("src.palette")

local Art = {}

Art.images   = {}   -- id -> love Image
Art.data     = {}   -- id -> love ImageData (para las siluetas y el contorno)
Art.sizes    = {}   -- id -> {w, h}
Art.list     = {}   -- orden de carga, para la barra del arranque
Art.fromFile = {}   -- id -> true si vino de art/

--==========================================================================
-- Lienzo de pixeles
--==========================================================================

local Canvas = {}
Canvas.__index = Canvas

local function newCanvas(w, h)
    return setmetatable({ w = w, h = h, data = love.image.newImageData(w, h) }, Canvas)
end

function Canvas:px(x, y, c, a)
    x, y = math.floor(x), math.floor(y)
    if x < 0 or y < 0 or x >= self.w or y >= self.h then return end
    self.data:setPixel(x, y, c[1], c[2], c[3], a or 1)
end

function Canvas:alpha(x, y)
    if x < 0 or y < 0 or x >= self.w or y >= self.h then return 0 end
    local _, _, _, a = self.data:getPixel(x, y)
    return a
end

function Canvas:rect(x, y, w, h, c)
    for iy = y, y + h - 1 do
        for ix = x, x + w - 1 do self:px(ix, iy, c) end
    end
end

function Canvas:hline(y, x0, x1, c)
    if x1 < x0 then x0, x1 = x1, x0 end
    for x = x0, x1 do self:px(x, y, c) end
end

function Canvas:vline(x, y0, y1, c)
    if y1 < y0 then y0, y1 = y1, y0 end
    for y = y0, y1 do self:px(x, y, c) end
end

function Canvas:disc(cx, cy, rx, ry, c)
    ry = ry or rx
    for y = math.floor(cy - ry), math.ceil(cy + ry) do
        for x = math.floor(cx - rx), math.ceil(cx + rx) do
            local nx = (x + 0.5 - cx) / (rx + 0.5)
            local ny = (y + 0.5 - cy) / (ry + 0.5)
            if nx * nx + ny * ny <= 1 then self:px(x, y, c) end
        end
    end
end

-- Poligono relleno por barrido, midiendo en el CENTRO del pixel. Es lo que
-- permite que la estrella del marcador y la punta del corazon salgan de la
-- misma funcion en vez de escribir cada silueta a mano.
function Canvas:poly(pts, c)
    local minY, maxY = math.huge, -math.huge
    for _, p in ipairs(pts) do
        if p[2] < minY then minY = p[2] end
        if p[2] > maxY then maxY = p[2] end
    end
    for y = math.floor(minY), math.ceil(maxY) do
        local yc = y + 0.5
        local cortes = {}
        for k = 1, #pts do
            local a, b = pts[k], pts[k % #pts + 1]
            if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then
                cortes[#cortes + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1])
            end
        end
        table.sort(cortes)
        for k = 1, #cortes - 1, 2 do
            for x = math.floor(cortes[k]), math.ceil(cortes[k + 1]) do
                if x + 0.5 >= cortes[k] and x + 0.5 <= cortes[k + 1] then self:px(x, y, c) end
            end
        end
    end
end

-- Pinta SOLO donde ya habia pixel: apunta lo que estaba vacio, deja pintar y
-- lo vuelve a vaciar. Es lo que permite dibujar una mancha con un disco -- que
-- es facil de describir -- y que se recorte sola contra una silueta que no lo
-- es. Sin esto, cada marca de la cara de Kiko habria que perseguirla a mano
-- por el canto de la cabeza.
function Canvas:recortar(pintar)
    local fuera = {}
    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            if self:alpha(x, y) == 0 then fuera[#fuera + 1] = { x, y } end
        end
    end
    pintar()
    for _, p in ipairs(fuera) do self.data:setPixel(p[1], p[2], 0, 0, 0, 0) end
end

-- Lo contrario: pinta solo donde NO habia nada, o sea, por DETRAS. Guarda el
-- lienzo entero, deja pintar y devuelve encima lo que ya estaba. Las orejas de
-- Kiko se dibujan asi: nacen dentro de la cabeza -- si no, no se sostienen --
-- pero lo unico que se ve de ellas es lo que asoma.
function Canvas:debajo(pintar)
    local antes = {}
    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            antes[#antes + 1] = { self.data:getPixel(x, y) }
        end
    end
    pintar()
    local k = 0
    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            k = k + 1
            if antes[k][4] > 0 then
                self.data:setPixel(x, y, antes[k][1], antes[k][2], antes[k][3], antes[k][4])
            end
        end
    end
end

-- Contorno de 1px POR FUERA de lo ya pintado. Se llama al final de cada
-- galleta: con el, seis siluetas distintas se leen sobre cualquier fondo, y es
-- lo unico que hace que una galleta pastel no se disuelva en el acero del bol.
-- Con la paleta vieja -- galletas vivas sobre casillas casi negras -- el
-- contorno era un remate; con pasteles sobre gris medio es lo que separa la
-- pieza del tablero, y quitarlo deja una mancha clara sin borde.
function Canvas:contorno(c)
    local marcas = {}
    for y = 0, self.h - 1 do
        for x = 0, self.w - 1 do
            if self:alpha(x, y) == 0 then
                if self:alpha(x - 1, y) > 0 or self:alpha(x + 1, y) > 0
                   or self:alpha(x, y - 1) > 0 or self:alpha(x, y + 1) > 0 then
                    marcas[#marcas + 1] = { x, y }
                end
            end
        end
    end
    for _, m in ipairs(marcas) do self:px(m[1], m[2], c) end
end

function Canvas:image()
    local img = love.graphics.newImage(self.data)
    img:setFilter("nearest", "nearest")
    return img
end

--==========================================================================
-- Siluetas de las galletas
--==========================================================================

-- Cada una dibuja su silueta en un lienzo de lado `s`. El centro es (s/2, s/2)
-- y el radio util es s/2 - 2: dos pixeles de aire, uno para el contorno y otro
-- para que dos galletas vecinas no se toquen. Sin ese segundo pixel el tablero
-- se lee como una sabana de color en vez de como ocho por ocho piezas.
local siluetas = {}

function siluetas.hueso(c, s, color)
    -- Galleta de hueso: cuatro lobulos y una barra. Los lobulos van a 3,4 del
    -- centro y no mas lejos: a cuatro se comen el pixel de aire y dos huesos
    -- vecinos se tocan por las puntas.
    local m = s / 2 - 0.5
    for _, x in ipairs({ m - 3.4, m + 3.4 }) do
        c:disc(x, m - 2.5, 1.9, 1.9, color)
        c:disc(x, m + 2.5, 1.9, 1.9, color)
    end
    -- La barra es dos pixeles mas estrecha que los lobulos por cada lado: esa
    -- cintura es lo unico que separa un hueso de un ladrillo a este tamano, y
    -- si la barra llega a lo ancho de los lobulos el sombreado la rellena.
    c:rect(m - 3.5, m - 1, 8, 3, color)
end

function siluetas.ondulada(c, s, color)
    -- Galleta redonda de borde ondulado: un disco pequeno y seis mordiscos por
    -- fuera. Con ocho ondas cada una mide pixel y medio y el borde se lee como
    -- un circulo mal dibujado; con seis, la onda mide dos pixeles y se ve.
    local m = s / 2 - 0.5
    c:disc(m, m, 3.2, 3.2, color)
    for k = 0, 5 do
        local a = k * math.pi / 3
        c:disc(m + math.cos(a) * 3.5, m + math.sin(a) * 3.5, 2.0, 2.0, color)
    end
end

function siluetas.medialuna(c, s, color)
    -- Gajo de limon: un disco al que otro disco le muerde el costado derecho.
    -- No hay primitiva para restar, asi que se mide cada pixel contra los dos
    -- circulos a la vez en vez de pintar y borrar.
    --
    -- Los tres numeros estan atados entre si y no se tocan por separado. El
    -- disco mide 5,9 y no 6 porque a 6 el filo de arriba cae en la fila 1 y el
    -- contorno se sale del sprite: la luna quedaria pegada a la de encima. El
    -- mordisco va 5,4 a la derecha y mide 5,6 -- un poco mas que el disco --
    -- porque asi el corte entra casi recto y deja el lomo en cinco pixeles y
    -- medio; con el mordisco mas centrado la luna adelgaza a una C de dos
    -- pixeles, que a este tamano se lee como un aro roto. Y el disco va 1,3
    -- a la derecha del centro para que la caja de la luna -- lomo mas cuernos
    -- -- quede centrada en la casilla, no el disco del que sale.
    local m = s / 2 - 0.5
    local cx, R = m + 1.3, 5.9
    local bx, r = m + 1.3 + 5.4, 5.6
    for y = 0, s - 1 do
        for x = 0, s - 1 do
            local px, py = x + 0.5, y + 0.5
            local dx, dy = px - cx, py - m
            local ex, ey = px - bx, py - m
            if dx * dx + dy * dy <= R * R and ex * ex + ey * ey > r * r then
                c:px(x, y, color)
            end
        end
    end
end

function siluetas.cruz(c, s, color)
    -- Palo en cruz: dos barras de cuatro pixeles con las cuatro puntas
    -- achaflanadas. El chaflan lo hace la barra estrecha que sobresale y no un
    -- disco: un disco de radio dos sobre una barra de cuatro sobra medio pixel
    -- por arriba y por abajo, y deja un bulto en mitad del canto.
    local m = s / 2 - 0.5
    c:rect(m - 1.5, m - 4.5, 4, 10, color)
    c:rect(m - 0.5, m - 5.5, 2, 12, color)
    c:rect(m - 4.5, m - 1.5, 10, 4, color)
    c:rect(m - 5.5, m - 0.5, 12, 2, color)
end

function siluetas.huella(c, s, color)
    -- Huella: almohadilla y cuatro dedos, los de fuera mas bajos y abiertos.
    -- Los dedos miden DOS pixeles con uno de hueco -- a tres se tocan entre
    -- ellos y la huella se lee como un disco mordido. El hueco se rellena
    -- solo: el contorno lo pinta de tinta y ahi es donde se separan los dedos.
    local m = s / 2 - 0.5
    c:disc(m, m + 3.5, 4.0, 2.9, color)
    c:disc(m - 4.5, m - 2.1, 0.95, 1.3, color)
    c:disc(m + 4.5, m - 2.1, 0.95, 1.3, color)
    c:disc(m - 1.5, m - 3.3, 0.95, 1.4, color)
    c:disc(m + 1.5, m - 3.3, 0.95, 1.4, color)
end

function siluetas.corazon(c, s, color)
    -- Corazon: dos lobulos y una punta. El valle de arriba mide un pixel justo
    -- -- con los lobulos mas juntos desaparece y queda un disco redondo -- y
    -- la punta se corta antes del suelo para no dejar un pixel suelto colgando.
    local m, r = s / 2 - 0.5, s / 2 - 2
    c:disc(m - 2.4, m - 1.6, 2.3, 2.2, color)
    c:disc(m + 2.4, m - 1.6, 2.3, 2.2, color)
    c:poly({ { m - r + 0.8, m - 1.6 }, { m + r - 0.8, m - 1.6 }, { m, m + r - 1.2 } }, color)
end

-- Esta no es una galleta: es la estrella del marcador de niveles, que usa la
-- misma maquinaria de poligonos. Vive aqui y no en su generador para no tener
-- dos formas de dibujar un poligono en el mismo archivo.
function siluetas.estrella(c, s, color)
    local m, R, r = s / 2, s / 2 - 1.2, (s / 2 - 1.2) * 0.44
    local pts = {}
    for k = 0, 9 do
        local ang = -math.pi / 2 + k * math.pi / 5
        local rad = (k % 2 == 0) and R or r
        pts[#pts + 1] = { m + math.cos(ang) * rad, m + math.sin(ang) * rad }
    end
    c:poly(pts, color)
end

-- El orden es el de Palette.galletas: el indice de color ES el indice de
-- silueta, y esa es toda la relacion que hay entre color y forma.
local FORMAS = { "hueso", "ondulada", "medialuna", "cruz", "huella", "corazon" }

--==========================================================================
-- La tuberia comun: silueta -> sombra -> luz -> brillo -> contorno
--==========================================================================

-- El sombreado no mira normales ni nada parecido: mide cada pixel contra un
-- foco arriba a la izquierda. Con seis siluetas distintas es lo unico que
-- sale igual de bien en todas; un degradado por filas se rompe en la estrella.
local function volumen(c, s, fam)
    local fx, fy = s * 0.33, s * 0.30
    local radio = s * 0.78
    local pintar = {}
    for y = 0, s - 1 do
        for x = 0, s - 1 do
            if c:alpha(x, y) > 0 then
                local dx, dy = (x + 0.5) - fx, (y + 0.5) - fy
                local d = math.sqrt(dx * dx + dy * dy) / radio
                if d < 0.34 then
                    pintar[#pintar + 1] = { x, y, fam.lite }
                elseif d > 0.92 then
                    pintar[#pintar + 1] = { x, y, fam.dark }
                end
            end
        end
    end
    for _, p in ipairs(pintar) do c:px(p[1], p[2], p[3]) end
end

-- El brillo especular. Es el mismo `miga` en las seis familias y va SIEMPRE
-- en el mismo sitio: es lo que las hermana y lo que hace que el tablero
-- parezca una bandeja iluminada desde arriba y no seis dibujos sueltos.
--
-- Con dos salvedades, y las dos son siluetas que tienen el hombro al aire: la
-- cruz y la huella no tienen pixel donde cae la luz. Ahi el brillo se muda al
-- pixel lleno mas cercano en vez de perderse, porque una pieza sin brillo en
-- un tablero donde las otras cinco lo llevan no se lee como otra forma, se lee
-- como una pieza apagada -- y apagado, en un match-3, significa bloqueado.
-- La busqueda barre en orden, asi que el resultado sigue siendo el mismo
-- siempre: los generadores no pueden sortear.
local function brillo(c, s)
    local x, y = math.floor(s * 0.30), math.floor(s * 0.22)
    if c:alpha(x, y) == 0 then
        local mejorX, mejorY, mejorD
        for py = 0, s - 1 do
            for px = 0, s - 1 do
                if c:alpha(px, py) > 0 then
                    local d = (px - x) * (px - x) + (py - y) * (py - y)
                    if not mejorD or d < mejorD then mejorX, mejorY, mejorD = px, py, d end
                end
            end
        end
        if not mejorD then return end
        x, y = mejorX, mejorY
    end
    if c:alpha(x, y) > 0 then c:px(x, y, Palette.miga) end
    if c:alpha(x + 1, y) > 0 then c:px(x + 1, y, Palette.miga) end
    if c:alpha(x, y + 1) > 0 then c:px(x, y + 1, Palette.miga) end
end

-- `forma` deja pedir la galleta con una silueta que no es la de su familia.
-- Solo la usa la estrella, que es una galleta entera con forma de estrella y no
-- una galleta con una estrella encima: un sello dentro de la silueta de la
-- familia sale partido en las dos que tienen hueco en medio -- la media luna
-- por la mordida y la huella entre los dedos y la almohadilla -- y lo que se
-- lee ahi no es una estrella, es suciedad. Cambiando la silueta entera, las
-- seis salen igual de limpias y se reconoce de un vistazo cual es la especial
-- que se reparte.
--
-- El precio esta contado: esta es la unica pieza del juego que NO se distingue
-- por la forma de su familia, asi que con daltonismo se ve que es una estrella
-- pero no de que color casa. Es una pieza suelta y rara -- una cada muchas
-- jugadas -- y por eso el cambio sale a cuenta; hacerlo con una galleta normal
-- romperia el juego entero.
local function galletaBase(s, indice, forma)
    local fam = Palette.galletas[indice]
    local c = newCanvas(s, s)
    siluetas[forma or FORMAS[indice]](c, s, fam.base)
    volumen(c, s, fam)
    brillo(c, s)
    c:contorno(Palette.ink)
    return c
end

-- Las rayas se pintan ENCIMA de la galleta ya hecha y solo donde hay pixel, asi
-- que se recortan solas contra cualquier silueta. Van paralelas a la racha que
-- las creo, que es lo mismo que decir que apuntan a donde van a disparar.
local function rayar(c, s, horizontal, fam)
    for y = 0, s - 1 do
        for x = 0, s - 1 do
            if c:alpha(x, y) > 0 then
                local t = horizontal and y or x
                local k = (t - math.floor(s / 2)) % 5
                -- Miga con su sombra debajo, y la sombra en el oscuro de la
                -- FAMILIA y no en tinta: con tinta la raya se lee como una
                -- reja por delante de la galleta y se come el color, que es lo
                -- que dice con quien casa.
                if k == 0 then c:px(x, y, Palette.miga)
                elseif k == 1 then c:px(x, y, fam.dark) end
            end
        end
    end
end

-- El envoltorio: un lazo de papel a los lados y dos pliegues en diagonal. No
-- se puede hacer con un marco -- taparia la silueta, que es lo que dice de que
-- color es -- asi que va por fuera, mordiendo solo las puntas.
local function envolver(c, s, fam)
    local m = s / 2
    for k = 0, 2 do
        c:vline(k, m - 2 - k, m + 1 + k, Palette.miga)
        c:vline(s - 1 - k, m - 2 - k, m + 1 + k, Palette.miga)
    end
    for y = 0, s - 1 do
        for x = 0, s - 1 do
            if c:alpha(x, y) > 0 then
                local d = math.abs((x - y))
                local e = math.abs((x + y) - (s - 1))
                if d <= 1 or e <= 1 then c:px(x, y, fam.lite) end
            end
        end
    end
    c:contorno(Palette.ink)
end

--==========================================================================
-- Generadores
--==========================================================================

local gen = {}

function gen.galleta(s, _, indice)
    return galletaBase(s, indice)
end

function gen.galletaRaya(s, _, indice, horizontal)
    local c = galletaBase(s, indice)
    rayar(c, s, horizontal, Palette.galletas[indice])
    return c
end

function gen.galletaEnvuelta(s, _, indice)
    local c = galletaBase(s, indice)
    envolver(c, s, Palette.galletas[indice])
    return c
end

-- La estrellada: la misma tuberia que cualquier galleta -- silueta, volumen,
-- brillo, contorno -- con la silueta cambiada. Por eso sale con el mismo
-- acabado que sus hermanas y no como una pieza pegada de otro juego, que es lo
-- que pasaria dibujandola aparte.
function gen.galletaEstrella(s, _, indice)
    return galletaBase(s, indice, "estrella")
end

-- El trozo que sale volando. Es una sola estrella pequena para las seis
-- familias y no seis sprites: el color se lo pone quien la dibuja, tintando su
-- silueta blanca (`Art.blanco`) con el de la galleta que la ha soltado. Es la
-- misma pieza para todas porque lo que tiene que leerse en vuelo no es de que
-- familia es -- eso ya lo dijo la estrella al romperse -- sino que va a algun
-- sitio.
--
-- Nueve pixeles de lado: mas pequena se pierde sobre el damero, y mas grande
-- tapa la galleta a la que llega justo cuando hay que verla reventar.
function gen.estrellita(s)
    local c = newCanvas(s, s)
    siluetas.estrella(c, s, Palette.miga)
    c:contorno(Palette.ink)
    return c
end

-- La pelota no tiene color porque es TODOS: un remolino con las seis
-- familias en orden. Es la unica pieza del juego que usa la paleta entera de
-- golpe, y por eso se reconoce de un vistazo aunque midan lo mismo que las
-- demas.
function gen.pelota(s)
    local c = newCanvas(s, s)
    local m = s / 2 - 0.5
    local r = s / 2 - 1.5
    for y = 0, s - 1 do
        for x = 0, s - 1 do
            local dx, dy = (x + 0.5) - (m + 0.5), (y + 0.5) - (m + 0.5)
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= r then
                local ang = math.atan2(dy, dx) / (math.pi * 2) + 0.5
                local k = math.floor((ang + d / r * 0.55) * 6) % 6 + 1
                local fam = Palette.galletas[k]
                c:px(x, y, d < r * 0.35 and fam.lite or fam.base)
            end
        end
    end
    c:px(math.floor(s * 0.30), math.floor(s * 0.22), Palette.miga)
    c:px(math.floor(s * 0.30) + 1, math.floor(s * 0.22), Palette.miga)
    c:contorno(Palette.ink)
    return c
end

-- La pastilla que hay que bajar: una capsula tumbada, mitad roja y mitad
-- crema. No casa con nada y por eso NO se parece a ninguna galleta: ninguna
-- familia es una capsula, ninguna esta partida en dos colores y ninguna lleva
-- un rojo saturado. Las tres cosas a la vez son lo que hace que se vea entrar
-- por arriba sin necesidad de buscarla.
--
-- Va TUMBADA y no de pie porque de pie mide catorce de alto por ocho de ancho
-- y a ese ancho las dos mitades salen de cuatro pixeles: la juntura deja de
-- leerse y la capsula se convierte en un boton bicolor. Tumbada, cada
-- mitad tiene siete de largo y se lee lo que es.
function gen.pastilla(s)
    local c = newCanvas(s, s)
    local m = s / 2
    local alto = math.floor(s * 0.5)            -- 8 de 16: el grosor
    local y0 = math.floor((s - alto) / 2)
    local x0, x1 = 2, s - 3                     -- los dos cantos redondeados

    -- El cuerpo: un rectangulo con las dos puntas redondeadas. Se pinta entero
    -- de crema y luego se repinta la mitad izquierda de rojo, que es una
    -- pasada menos que perseguir el borde curvo dos veces.
    c:disc(x0 + alto / 2 - 0.5, m - 0.5, alto / 2, alto / 2, Palette.pastillaCrema)
    c:disc(x1 - alto / 2 + 0.5, m - 0.5, alto / 2, alto / 2, Palette.pastillaCrema)
    c:rect(x0 + 1, y0, x1 - x0 - 1, alto, Palette.pastillaCrema)
    for y = 0, s - 1 do
        for x = 0, math.floor(m) - 1 do
            if c:alpha(x, y) > 0 then c:px(x, y, Palette.pastilla) end
        end
    end

    -- La juntura: la mitad roja monta un pixel sobre la crema y ese canto va
    -- en el rojo oscuro. Sin juntura, las dos mitades se leen como una mancha
    -- mal pintada y no como una capsula que se abre.
    c:vline(math.floor(m) - 1, y0, y0 + alto - 1, Palette.pastillaDark)

    -- Volumen: la fila de abajo de cada mitad en su tono oscuro y la de arriba
    -- en el claro. Es el mismo reparto de luz que llevan las galletas (arriba a
    -- la izquierda), que es lo que la mantiene en la misma hornada aunque no
    -- sea comida.
    for y = 0, s - 1 do
        for x = 0, s - 1 do
            if c:alpha(x, y) > 0 then
                local rojo = x < math.floor(m)
                if y >= y0 + alto - 2 then
                    c:px(x, y, rojo and Palette.pastillaDark or Palette.pastillaSombra)
                elseif y <= y0 + 1 and x > x0 + 1 and x < x1 - 1 then
                    c:px(x, y, rojo and Palette.pastillaLite or Palette.miga)
                end
            end
        end
    end

    -- El brillo especular, dos pixeles, en el mismo sitio que el de las
    -- galletas: arriba a la izquierda, sobre la mitad roja.
    c:px(x0 + 2, y0 + 1, Palette.miga)
    c:px(x0 + 3, y0 + 1, Palette.miga)

    c:contorno(Palette.ink)
    return c
end

-- La casilla del tablero. Dos tonos alternos (damero) para que se lea la
-- rejilla sin dibujar ni una linea: una rejilla de lineas compite con las
-- rayas de las especiales y marea.
function gen.casilla(s, _, alterna)
    local c = newCanvas(s, s)
    local base = alterna and Palette.huecoAlt or Palette.hueco
    c:rect(1, 1, s - 2, s - 2, base)
    c:hline(1, 1, s - 2, Palette.mix(base, Palette.ink, 0.35))
    c:hline(s - 2, 1, s - 2, Palette.mix(base, Palette.miga, 0.06))
    -- Las cuatro esquinas se pintan del color del FONDO DEL BOL y no de tinta:
    -- redondean la casilla igual, pero en tinta las sesenta y cuatro casillas
    -- ponen doscientos cincuenta y seis puntos negros sobre el acero y eso se
    -- lee como suciedad, no como una rejilla.
    c:px(1, 1, Palette.metalDark); c:px(s - 2, 1, Palette.metalDark)
    c:px(1, s - 2, Palette.metalDark); c:px(s - 2, s - 2, Palette.metalDark)
    return c
end

-- Ruido de valor, determinista y sin estado: la misma casilla da siempre los
-- mismos pixeles, que es la regla de esta casa (ningun `love.math.random` aqui
-- dentro). Es el hash del seno de toda la vida: no es buen ruido, pero para
-- decidir si un pixel lleva barro o no sobra.
local function ruido(x, y, sal)
    local n = math.sin(x * 12.9898 + y * 78.233 + sal * 37.719) * 43758.5453
    return n - math.floor(n)
end

-- El barro se dibuja con TRAMA y no con alpha: pixel opaco o pixel que no
-- esta. Con alpha habria que mezclar con lo que hubiera debajo y el barro
-- acabaria tintando el acero del bol; con trama se ve la mancha y se ve la
-- casilla, cada una en sus pixeles.
--
-- Lo que cambia respecto de la trama de damero que habia es que la densidad se
-- decide con RUIDO EN GRUMOS -- el ruido se muestrea en bloques de dos por dos
-- y se le suma un poco de ruido por pixel -- y no con `(x + y) % 2`. Un damero
-- regular se lee como una textura de juego, como una rejilla puesta encima;
-- los grumos se leen como algo que ha salpicado. Son los mismos pixeles
-- pintados y la diferencia es entera del ojo.
--
-- Tampoco lleva marco: el marco cuadraba la mancha con la casilla y eso es lo
-- que delataba que el barro era una casilla pintada y no barro.
--
-- Las dos capas se distinguen por DOS cosas a la vez y no por una: la segunda
-- es mas oscura y ademas cubre casi toda la casilla. Solo por color, con el
-- acero del bol de por medio, no se veia cual llevaba dos.
function gen.barro(s, _, capas)
    local c = newCanvas(s, s)
    local color    = capas >= 2 and Palette.barro2 or Palette.barro
    local hondo    = Palette.mix(color, Palette.ink, 0.35)
    local densidad = capas >= 2 and 0.80 or 0.55
    local sal      = capas >= 2 and 7 or 3

    for y = 1, s - 2 do
        for x = 1, s - 2 do
            local v = 0.65 * ruido(math.floor(x / 2), math.floor(y / 2), sal)
                    + 0.35 * ruido(x, y, sal + 1)
            if v < densidad then
                -- Los grumos mas cerrados van en un tono mas oscuro: es lo que
                -- le da espesor al barro en vez de dejarlo como una mancha
                -- plana de un solo color.
                c:px(x, y, v < densidad * 0.45 and hondo or color)
            elseif capas == 1 and v > 0.80 then
                -- Y en la capa fina, diez pixeles sueltos de costra seca en
                -- lo mas claro de la mancha. Sin ellos, el barro de una capa
                -- se parece demasiado al de dos a medio limpiar. El umbral
                -- esta medido: por encima de 0,85 no sale ni uno.
                c:px(x, y, Palette.barroLite)
            end
        end
    end
    return c
end

-- El moho: el barro que CRECE, y por eso se dibuja al reves que el barro.
--
-- El barro cubre la casilla entera de grumos; el moho son COLONIAS redondas
-- con el suelo del bol a la vista entre ellas. Los dos van a coincidir en el
-- mismo bol y la diferencia no puede ser solo el tono -- un "barro verde" es
-- justo lo que este juego no se permite ni en las galletas, donde la forma
-- manda sobre el color y por eso hay seis siluetas.
--
-- Cuatro colonias de tamanos distintos y ninguna centrada: una sola mancha en
-- medio de la casilla se lee como una ficha puesta encima, y cuatro repartidas
-- se leen como algo que ha ido saliendo por su cuenta. El canto de cada una se
-- muerde con el mismo ruido que el barro (un circulo limpio a dieciseis
-- pixeles se lee como un boton) y el borde va en el tono claro: es lo que hace
-- que la mancha parezca pelusa en vez de una gota.
function gen.moho(s)
    local c = newCanvas(s, s)
    local hondo = Palette.mix(Palette.moho, Palette.ink, 0.35)
    -- Cinco colonias PEQUENAS y no cuatro grandes: con radios de mas se
    -- funden entre si, y lo que queda es una sabana verde con agujeros -- o
    -- sea, barro de otro color. El suelo del bol tiene que verse ENTRE las
    -- manchas, que es lo unico que dice que esto ha ido saliendo por sitios.
    local colonias = {
        { x = 0.34, y = 0.36, r = 0.21 },
        { x = 0.70, y = 0.64, r = 0.18 },
        { x = 0.26, y = 0.74, r = 0.13 },
        { x = 0.74, y = 0.24, r = 0.11 },
        { x = 0.50, y = 0.86, r = 0.09 },
    }
    for y = 1, s - 2 do
        for x = 1, s - 2 do
            for _, col in ipairs(colonias) do
                local dx = (x + 0.5) - col.x * s
                local dy = (y + 0.5) - col.y * s
                local d = math.sqrt(dx * dx + dy * dy)
                local borde = col.r * s * (0.80 + 0.30 * ruido(x, y, 21))
                if d <= borde then
                    -- Tres anillos: el corazon oscuro, la carne y la pelusa
                    -- del borde. Son los mismos tres tonos con los que el
                    -- barro se da espesor, puestos por distancia en vez de por
                    -- densidad de ruido, que es lo que hace que estas manchas
                    -- tengan volumen de bola y las del barro no.
                    local nucleo = d < borde * 0.40
                    local canto  = d > borde * 0.62
                    c:px(x, y, nucleo and hondo or (canto and Palette.mohoLite or Palette.moho))
                    break
                end
            end
        end
    end
    return c
end

-- El cubito de hielo. Se dibuja ENCIMA de la galleta, y eso plantea el mismo
-- problema que el barro: el arte no usa alpha nunca, y un cubito opaco taparia
-- lo que hay dentro -- que es justo lo que el jugador necesita ver para saber
-- si le interesa romperlo.
--
-- El barro lo resolvio con trama cerrada, pero aqui la trama no vale: el barro
-- puede permitirse tapar porque debajo solo hay tablero, y debajo del cubito
-- hay una galleta que hay que reconocer por su silueta. Asi que el cubito es
-- casi todo AIRE y el trabajo lo hace el canto: marco de un pixel, las cuatro
-- esquinas engordadas -- las aristas del cubo -- y cuatro rayas sueltas
-- dentro. Con el marco solo se lee como una ventana; son las esquinas las que
-- lo convierten en un bloque visto de frente.
--
-- La luz cae arriba a la izquierda, como en el bol y como en las galletas: el
-- canto de arriba y el de la izquierda son los claros. Y el brillo son dos
-- rayas cortas en diagonal por la misma razon que el del acero -- un reflejo
-- entero se lee como un borde pintado y uno partido se lee como cristal.
function gen.hielo(s)
    local c = newCanvas(s, s)
    local claro, medio, hondo = Palette.hieloLite, Palette.hielo, Palette.hieloDark

    -- El canto va ENTERO en el tono oscuro y la luz entra por dentro. Es al
    -- reves que en el bol, y es por el fondo: el bol se recorta contra el
    -- mantel crema y el cubito se recorta contra una galleta pastel, que es
    -- casi tan clara como el hielo. Un canto claro sobre una galleta clara no
    -- es un canto -- y sin canto, el cubito es un reflejo y no una caja.
    c:hline(0, 0, s - 1, hondo)
    c:vline(0, 0, s - 1, hondo)
    c:hline(s - 1, 0, s - 1, hondo)
    c:vline(s - 1, 0, s - 1, hondo)


    -- Las esquinas, en cuna: tres pixeles, dos y uno hacia dentro. Son las
    -- ARISTAS del cubo y son lo que mas trabaja de todo el sprite -- con el
    -- marco solo, esto es una galleta dentro de una ventana; con las cunas, es
    -- una galleta dentro de un bloque.
    local function cuna(x, y, dx, dy, col)
        for fila = 0, 2 do
            for k = 0, 2 - fila do c:px(x + dx * k, y + dy * fila, col) end
        end
    end
    cuna(1, 1, 1, 1, claro)
    cuna(s - 2, 1, -1, 1, medio)
    cuna(1, s - 2, 1, -1, medio)
    cuna(s - 2, s - 2, -1, -1, medio)

    -- Y el interior: dos rayas del color del hielo y dos de brillo, todas
    -- cortas y en la misma diagonal. Cuatro son las que hacen falta para que
    -- se lea que hay algo delante de la galleta; con una mas ya es un cristal
    -- esmerilado y la galleta deja de reconocerse.
    local function raya(x, y, largo, col)
        for k = 0, largo - 1 do c:px(x + k, y - k, col) end
    end
    raya(3, 7, 4, Palette.miga)
    raya(9, 5, 2, Palette.miga)
    raya(9, 12, 3, medio)
    raya(4, 13, 2, medio)

    return c
end

-- El bol de la portada: el mismo cuenco de acero del tablero, pero visto DE
-- LADO Y DESDE ARRIBA -- un bol de perro de verdad, con su boca abierta en
-- ovalo, su panza y su pie ancho.
--
-- Sustituye a la chapa rectangular que habia antes por una razon: la portada
-- tiene que prometer lo que hay dentro, y lo que hay dentro es un bol. Una
-- chapa con el nombre grabado promete una placa; un bol con el nombre grabado
-- en la panza es el cacharro del perro, que es de lo que va el juego.
--
-- La perspectiva esta hecha con TRES elipses y ninguna rotacion (nada se
-- dibuja girado en este juego): la boca, el pie y el contorno de la panza, que
-- es lo que queda entre las dos. Que se lea como un volumen y no como un
-- dibujo plano es cosa de dos detalles: la boca ensena mas pared por DENTRO
-- arriba que abajo -- se mira desde arriba, asi que la pared del fondo se ve
-- entera y la de delante casi no --, y la panza se estrecha hacia abajo con
-- una curva y no con una recta, que es lo que separa un bol de un cubo.
--
-- El pie es MAS ANCHO que el fondo de la panza. Eso no es estilo: es lo que
-- distingue un bol de perro de un bol de ensalada, porque es lo que hace que
-- no vuelque cuando lo empujan con el morro.
function gen.bol(w, h)
    local c = newCanvas(w, h)
    -- Las medidas van escritas sobre una rejilla de 112x58 y se escalan, como
    -- la cara de Kiko: un bol no se describe con un radio.
    local function ux(v) return v * w / 112 end
    local function uy(v) return v * h / 58 end

    local cx     = ux(56)
    local yBoca  = uy(12)
    local rxBoca, ryBoca = ux(54), uy(8.5)
    local yPie   = uy(47)
    local rxPie,  ryPie  = ux(32), uy(5)
    local rxPanza = ux(26)          -- el fondo de la panza, mas estrecho que el pie

    -- La panza. Cada fila es una linea horizontal cuyo ancho va de la boca al
    -- fondo con la curva metida en el exponente: con `t` a secas sale un cono,
    -- y un cono con un ovalo encima se lee como un cubo de fregona.
    local function anchoEn(y)
        local t = (y - yBoca) / (yPie - yBoca)
        t = math.min(1, math.max(0, t))
        return rxBoca + (rxPanza - rxBoca) * (t ^ 1.35)
    end

    for y = math.floor(yBoca), math.floor(yPie) do
        local hw = anchoEn(y)
        for x = math.floor(cx - hw), math.ceil(cx + hw) do
            -- La luz cae arriba a la izquierda, como en todo el juego, asi que
            -- el acero se lee en bandas VERTICALES: el canto de la izquierda
            -- recoge la luz, el centro es el cuerpo y la derecha se va a la
            -- sombra. Medido contra el ancho de la fila y no en pixeles, que es
            -- lo que mantiene las bandas paralelas al canto segun se estrecha.
            local nx = (x + 0.5 - cx) / hw
            local col = Palette.metal
            if nx <= -0.86 then col = Palette.metalLite
            elseif nx >= 0.76 then col = Palette.metalDark end
            c:px(x, y, col)
        end
    end

    -- El reflejo de la panza: una raya corta y vertical en el tercio
    -- izquierdo, y solo en la mitad de arriba. Es el mismo truco que los dos
    -- brillos del canto del bol del tablero -- corto e interrumpido se lee como
    -- acero pulido, largo y entero se lee como un bisel de ventana.
    for y = math.floor(yBoca + uy(6)), math.floor(yBoca + uy(15)) do
        local hw = anchoEn(y)
        local x = math.floor(cx - hw * 0.64)
        c:px(x, y, Palette.metalLite)
        c:px(x + 1, y, Palette.metalShine)
    end

    -- El pie. Es MAS ANCHO que el fondo de la panza, y eso no es estilo: es lo
    -- que distingue un bol de perro de uno de ensalada, porque es lo que hace
    -- que no vuelque cuando lo empujan con el morro.
    --
    -- Se dibuja como un ovalo con su propia luz -- claro arriba, oscuro por
    -- debajo -- y no como un bloque: un pie plano convierte el bol en un
    -- jarron, porque un jarron es justo eso, una panza sin pie.
    c:disc(cx, yPie, rxPie, ryPie, Palette.metalDark)
    c:disc(cx, yPie - uy(1), rxPie - ux(1.5), ryPie - uy(0.6), Palette.metal)
    c:disc(cx, yPie - uy(1.8), rxPie - ux(5), ryPie - uy(1.8), Palette.metalLite)
    -- La mitad de la derecha del pie se va a la sombra, como todo lo demas. Es
    -- lo unico que impide que el pie se lea como un aro iluminado por delante
    -- mientras el bol que tiene encima esta iluminado desde la izquierda.
    for y = math.floor(yPie - ryPie), math.floor(yPie + ryPie) do
        for x = math.floor(cx + rxPie * 0.55), math.ceil(cx + rxPie) do
            if c:alpha(x, y) > 0 then c:px(x, y, Palette.metalDark) end
        end
    end

    -- La sombra de contacto: donde la panza se posa en el pie. Es un ovalo
    -- FINO pegado al fondo de la panza y no una banda ancha -- ancha se lee
    -- como un aro pintado, fina se lee como el sitio donde no entra la luz.
    c:disc(cx, yPie - uy(2.6), rxPanza + ux(0.5), uy(1.6), Palette.metalDark)

    -- La boca. De fuera hacia dentro: el canto del labio, el labio iluminado
    -- (subido un pixel, que es lo que le da grosor por abajo) y el hueco.
    c:disc(cx, yBoca, rxBoca, ryBoca, Palette.metalDark)
    c:disc(cx, yBoca - uy(1), rxBoca - ux(0.5), ryBoca - uy(0.5), Palette.metalLite)

    -- Lo de dentro va BAJADO respecto al labio. Ese desplazamiento es toda la
    -- perspectiva del bol: deja una banda gorda de pared arriba -- la del
    -- fondo, que se ve entera desde arriba -- y una fina abajo, que es la de
    -- delante vista casi de canto. Centrado, el bol se leeria como un aro.
    --
    -- La pared del fondo, ademas, BRILLA: dentro de un cacharro de acero es lo
    -- primero que coge la luz, y sin ella la boca se lee como una mancha
    -- oscura pegada encima de la panza en vez de como un hueco. Se dibuja sola
    -- -- el mismo ovalo dos veces, el claro un pixel mas arriba -- y lo que
    -- asoma por el canto de arriba es exactamente esa pared.
    local rxDentro, ryDentro = rxBoca - ux(6.5), ryBoca - uy(2.6)
    c:disc(cx, yBoca + uy(1.6), rxDentro, ryDentro, Palette.metal)
    c:disc(cx, yBoca + uy(2.4), rxDentro, ryDentro, Palette.metalDark)
    -- Y el hondo, que es lo que hace que la boca sea un AGUJERO y no un plato:
    -- mas oscuro que cualquier acero de la paleta, porque ahi dentro no llega
    -- la luz de la cocina. Tirado hacia la tinta y no la tinta misma -- en
    -- tinta pura el bol se queda con un boquete negro en medio y deja de
    -- parecer metal.
    c:disc(cx, yBoca + uy(3.6), rxBoca - ux(9.5), ryBoca - uy(3.6),
           Palette.mix(Palette.metalDark, Palette.ink, 0.45))

    -- Los dos brillos del labio, cortos y separados, en el tercio izquierdo.
    for i, tramo in ipairs({ { -0.62, -0.44 }, { -0.34, -0.28 } }) do
        for x = math.floor(cx + rxBoca * tramo[1]), math.floor(cx + rxBoca * tramo[2]) do
            local y0 = math.floor(yBoca - ryBoca - 1)
            -- Se pinta el primer pixel de labio que se encuentra bajando: un
            -- brillo que se salga del ovalo le hace una antena al bol.
            for dy = 0, 3 do
                if c:alpha(x, y0 + dy) > 0 then
                    c:px(x, y0 + dy, Palette.metalShine)
                    c:px(x, y0 + dy + 1, Palette.metalShine)
                    break
                end
            end
        end
    end

    c:contorno(Palette.ink)
    return c
end

-- La estrella del marcador de niveles. Se dibuja rellena o vacia segun haga
-- falta, y son dos sprites y no uno con un tinte porque una estrella apagada
-- no es una estrella oscura: es un hueco con borde.
function gen.estrella(s, _, llena)
    local c = newCanvas(s, s)
    -- La apagada se rellena con `uiLine` y no con el fondo del panel: sobre la
    -- barra clara, una estrella del color del fondo es una estrella que no
    -- esta.
    siluetas.estrella(c, s, llena and Palette.gold or Palette.uiLine)
    if llena then
        for y = 0, s - 1 do
            for x = 0, s - 1 do
                if c:alpha(x, y) > 0 and (x + y) < s * 0.8 then
                    c:px(x, y, Palette.mix(Palette.gold, Palette.miga, 0.5))
                end
            end
        end
    end
    -- Las dos llevan contorno oscuro: sobre cremas claras, un contorno claro
    -- deja la estrella sin canto y a este tamano eso la borra.
    c:contorno(llena and Palette.ink or Palette.dim)
    return c
end

--==========================================================================
-- La hoja de Kiko
--==========================================================================

-- Kiko es lo UNICO de este juego que no se genera: son sesenta y cuatro caras
-- dibujadas a mano en una hoja de ocho por ocho (`art/kiko.png`, 32x32 cada
-- una), y entran por la misma puerta por la que entra cualquier arte de mano
-- (ver `Art.step`), solo que de golpe.
--
-- El motivo de que el perro se salga de la regla es que dejo de ser un icono.
-- Un generador de discos y poligonos da UNA cara -- la de siempre, la que
-- estaba en la cabecera -- y lo que hace falta ahora son las otras: bostezar,
-- dormirse, mirar de lado cuando queda poco, poner la oreja al ultimo
-- movimiento. Eso es dibujo, no geometria, y describir a golpe de elipses el
-- morro abierto de un bostezo sale peor que dibujarlo.
--
-- Cada fotograma se recorta al arrancar y se mete en el registro como un
-- sprite mas, con su id (`Art.idKiko(16)` -> "kiko.16"): todo lo que sabe
-- dibujar un sprite sabe dibujar una cara de Kiko sin enterarse de que viene
-- de una hoja.
--
-- El numero de un fotograma es el de la hoja -- DECENA la columna, UNIDAD la
-- fila, empezando por el 11 arriba a la izquierda -- y no un indice del 1 al
-- 64. Es como estan numeradas las caras desde que se dibujaron: renumerarlas
-- aqui obligaria a traducir cada vez que alguien mire la hoja para elegir una.
Art.KIKO_LADO = 32
local KIKO_COLS, KIKO_FILAS = 8, 8

function Art.idKiko(codigo) return "kiko." .. codigo end

-- Un fotograma recortado de la hoja, en ImageData.
--
-- El alpha se REDONDEA, y no es mania: en este juego un pixel es opaco o no
-- esta (ver `art/README.md`), y la hoja trae unos cuantos cantos a 254 y a 1
-- -- restos del programa con el que se dibujo -- que a escala cuatro serian
-- los unicos pixeles translucidos de la pantalla.
--
-- Recibe la hoja ya cargada y no su nombre porque lo usa tambien el generador
-- del icono (`icono/main.lua`), que vive en otra carpeta y no puede pedirle
-- nada a `love.filesystem`.
function Art.recorte(hoja, codigo)
    local lado = Art.KIKO_LADO
    local col, fila = math.floor(codigo / 10) - 1, codigo % 10 - 1
    local d = love.image.newImageData(lado, lado)
    d:paste(hoja, 0, 0, col * lado, fila * lado, lado, lado)
    d:mapPixel(function(_, _, r, g, b, a)
        if a < 0.5 then return 0, 0, 0, 0 end
        return r, g, b, 1
    end)
    return d
end

-- La hoja entera, de una vez: sesenta y cuatro sprites en un solo paso de la
-- barra del arranque. Cortarlos uno por paso dejaria la barra contando caras
-- de perro durante dos tercios de la carga, y lo que cuesta de verdad es leer
-- el PNG, que se hace una sola vez.
local function cargarHoja(entrada)
    local ruta = "art/" .. entrada.archivo
    -- Sin hoja no hay perro, y un perro que falta no se ve como un fallo: se
    -- ve como una cabecera con un hueco. Mejor reventar aqui y decirlo.
    if not love.filesystem.getInfo(ruta) then
        error("falta la hoja de Kiko: " .. ruta)
    end

    local hoja = love.image.newImageData(ruta)
    for col = 1, KIKO_COLS do
        for fila = 1, KIKO_FILAS do
            local id = Art.idKiko(col * 10 + fila)
            local d = Art.recorte(hoja, col * 10 + fila)
            local img = love.graphics.newImage(d)
            img:setFilter("nearest", "nearest")
            Art.images[id] = img
            Art.data[id] = d
            Art.sizes[id] = { w = Art.KIKO_LADO, h = Art.KIKO_LADO }
            Art.fromFile[id] = true
        end
    end

    -- Al desfile del arranque va UNA cara y no las sesenta y cuatro: la cinta
    -- de sprites de `boot.lua` ensena los ultimos doce, y con la hoja entera
    -- dentro no ensenaria otra cosa.
    Art.list[#Art.list + 1] = Art.idKiko(11)
end

--==========================================================================
-- Registro
--==========================================================================

local T = Constants.TILE
local SPRITES = {}

local function registrar(id, w, h, archivo, generador, ...)
    SPRITES[#SPRITES + 1] = { id = id, w = w, h = h, archivo = archivo,
                              gen = generador, args = { ... } }
end

-- Los ids de las galletas se piden con estas dos funciones y no se escriben a
-- mano en ningun sitio: asi una familia nueva no obliga a buscar cadenas.
function Art.idGalleta(color, especial)
    if especial == "pelota" then return "pelota" end
    local key = Palette.galletas[color].key
    if especial then return "galleta." .. key .. "." .. especial end
    return "galleta." .. key
end

for indice, fam in ipairs(Palette.galletas) do
    registrar("galleta." .. fam.key, T, T, fam.key .. ".png", gen.galleta, indice)
    registrar("galleta." .. fam.key .. ".rayaH", T, T, fam.key .. "_rayaH.png",
              gen.galletaRaya, indice, true)
    registrar("galleta." .. fam.key .. ".rayaV", T, T, fam.key .. "_rayaV.png",
              gen.galletaRaya, indice, false)
    registrar("galleta." .. fam.key .. ".envuelta", T, T, fam.key .. "_envuelta.png",
              gen.galletaEnvuelta, indice)
    registrar("galleta." .. fam.key .. ".estrella", T, T, fam.key .. "_estrella.png",
              gen.galletaEstrella, indice)
end

registrar("pelota",   T, T, "pelota.png",   gen.pelota)
registrar("pastilla",       T, T, "pastilla.png",       gen.pastilla)
registrar("casilla",    T, T, "casilla.png",    gen.casilla, false)
registrar("casillaAlt", T, T, "casilla_alt.png",gen.casilla, true)
registrar("barro1",  T, T, "barro1.png",  gen.barro, 1)
registrar("barro2",  T, T, "barro2.png",  gen.barro, 2)
registrar("moho",    T, T, "moho.png",    gen.moho)
registrar("hielo",   T, T, "hielo.png",   gen.hielo)
-- La hoja de Kiko: una fila como las demas, pero sin generador. Se carga
-- entera en su paso (`cargarHoja`) y deja sesenta y cuatro sprites.
SPRITES[#SPRITES + 1] = { id = "kiko", archivo = "kiko.png", hoja = true }
registrar("estrellita", 9,  9,  "estrellita.png",   gen.estrellita)
registrar("estrella",   12, 12, "estrella.png",     gen.estrella, true)
registrar("estrellaOff",12, 12, "estrella_off.png", gen.estrella, false)
-- El bol de la portada. Es el sprite mas grande del juego con diferencia, y
-- se genera igual que el resto: 112 de ancho son 448 virtuales a escala 4, que
-- es lo que cabe en el lienzo de 540 dejando aire a los lados.
registrar("bol", 112, 58, "bol.png", gen.bol)

Art.SPRITES = SPRITES
Art.count = #SPRITES

--==========================================================================
-- Carga
--==========================================================================

local cursor = 0

-- Un sprite por llamada: la pantalla de arranque los pide en bucle para poder
-- pintar la barra entre uno y otro en vez de congelarse en negro.
function Art.step()
    cursor = cursor + 1
    local entrada = SPRITES[cursor]
    if not entrada then return true, 1 end

    -- Una hoja no es un sprite: es un paso que deja muchos, y se apunta a la
    -- lista del desfile por dentro (`cargarHoja`).
    if entrada.hoja then
        cargarHoja(entrada)
        return cursor >= #SPRITES, cursor / #SPRITES
    end

    local ruta = "art/" .. entrada.archivo
    if love.filesystem.getInfo(ruta) then
        local data = love.image.newImageData(ruta)
        local img = love.graphics.newImage(data)
        img:setFilter("nearest", "nearest")
        Art.images[entrada.id] = img
        Art.data[entrada.id] = data
        Art.sizes[entrada.id] = { w = img:getWidth(), h = img:getHeight() }
        Art.fromFile[entrada.id] = true
    else
        local c = entrada.gen(entrada.w, entrada.h, unpack(entrada.args))
        Art.images[entrada.id] = c:image()
        Art.data[entrada.id] = c.data
        Art.sizes[entrada.id] = { w = entrada.w, h = entrada.h }
        Art.fromFile[entrada.id] = false
    end

    Art.list[#Art.list + 1] = entrada.id
    return cursor >= #SPRITES, cursor / #SPRITES
end

function Art.loadAll()
    local fin = false
    repeat fin = Art.step() until fin
end

function Art.get(id)
    local img = Art.images[id]
    if not img then error("sprite desconocido: " .. tostring(id)) end
    return img
end

function Art.size(id)
    local s = Art.sizes[id]
    return s.w, s.h
end

-- Lo que un sprite deja en blanco por su izquierda, en pixeles de arte.
--
-- Cada silueta deja el suyo: la estrella uno, el limon dos, la pastilla
-- ninguno. La cabecera lo resta al colocar el icono de un objetivo, y por eso
-- todos los objetivos empiezan en la misma columna: sin restarlo, la sangria
-- del bloque mide un pixel distinto en cada nivel y eso no se lee como un
-- sprite mas ancho, se lee como un bloque torcido.
--
-- Se mide una vez por sprite y se guarda: recorrer una imagen de 16x16 es
-- barato, hacerlo sesenta veces por segundo no hace falta.
local margenes = {}

function Art.margenIzq(id)
    local m = margenes[id]
    if m then return m end

    local data = Art.data[id]
    local w, h = Art.size(id)
    m = w
    for y = 0, h - 1 do
        for x = 0, m - 1 do
            local _, _, _, a = data:getPixel(x, y)
            if a > 0 then m = x break end
        end
        if m == 0 then break end
    end
    if m >= w then m = 0 end      -- un sprite vacio no tiene margen

    margenes[id] = m
    return m
end

--==========================================================================
-- Siluetas blancas
--==========================================================================

-- La misma forma, toda de miga. Es el fogonazo de una galleta al romperse:
-- un fotograma en blanco antes de estallar, que es lo que convierte un
-- "ha desaparecido" en un "la he roto".
--
-- No se puede hacer tintando el sprite (setColor multiplica, y multiplicar por
-- blanco deja el sprite igual), asi que hace falta el sprite aparte. Se genera
-- la primera vez que se pide y se guarda.
local siluetasBlancas = {}

function Art.blanco(id)
    if siluetasBlancas[id] then return siluetasBlancas[id] end
    local data = Art.data[id]
    local w, h = Art.size(id)
    local c = newCanvas(w, h)
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local _, _, _, a = data:getPixel(x, y)
            if a > 0 then c:px(x, y, Palette.miga) end
        end
    end
    local img = c:image()
    siluetasBlancas[id] = img
    return img
end

--==========================================================================
-- Dibujo
--==========================================================================

-- Todo en espacio de ARTE y con la posicion redondeada: medio pixel de arte
-- son cuatro de pantalla y se ve.
function Art.draw(id, x, y)
    love.graphics.draw(Art.get(id), math.floor(x), math.floor(y))
end

function Art.drawCentered(id, x, y)
    local w, h = Art.size(id)
    love.graphics.draw(Art.get(id), math.floor(x - w / 2), math.floor(y - h / 2))
end

-- Centrado y ESCALADO, que es como se anima un reventon o un rebote.
--
-- La escala se redondea a pixeles enteros del sprite: un sprite de 16 a escala
-- 1.31 mide 20,96 px y el borde queda a medio pixel, que con la escala de arte
-- encima son cuatro pixeles de pantalla borrosos. Redondeando, la galleta
-- crece a saltos de un pixel de arte -- que es justo el aspecto de un juego de
-- pixeles hinchandose, y se lee mas "crujiente" que el crecimiento continuo.
function Art.drawScaled(id, x, y, sx, sy)
    sy = sy or sx
    local w, h = Art.size(id)
    local pw = math.max(0, math.floor(w * sx + 0.5))
    local ph = math.max(0, math.floor(h * sy + 0.5))
    if pw == 0 or ph == 0 then return end
    love.graphics.draw(Art.get(id), math.floor(x - pw / 2), math.floor(y - ph / 2),
                       0, pw / w, ph / h)
end

function Art.drawBlanco(id, x, y, sx, sy)
    sy = sy or sx or 1
    sx = sx or 1
    local w, h = Art.size(id)
    local pw = math.max(0, math.floor(w * sx + 0.5))
    local ph = math.max(0, math.floor(h * sy + 0.5))
    if pw == 0 or ph == 0 then return end
    love.graphics.draw(Art.blanco(id), math.floor(x - pw / 2), math.floor(y - ph / 2),
                       0, pw / w, ph / h)
end

return Art
