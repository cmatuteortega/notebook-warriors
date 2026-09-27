-- La portada: el nombre, el perro y las dos maneras de jugar.
--
-- Existe porque hay DOS juegos aqui dentro y el mapa no puede ser la puerta de
-- los dos: un mapa de niveles con un boton de arcade en una esquina dice que
-- el arcade es un extra del mapa, y no lo es -- es la otra mitad. Puestos los
-- dos en el centro de una pantalla vacia, elegir es lo primero que se hace y
-- se hace una vez.
--
-- El nombre va GRABADO EN ACERO sobre EL BOL DEL PERRO, visto de lado y desde
-- arriba (`gen.bol` en `src/art.lua`). Es el mismo grabado que lleva el faldon
-- del bol debajo del tablero (`dibujarNombre` en la pantalla de juego): la
-- copia clara abajo y a la derecha, la oscura encima, y la luz cayendo siempre
-- arriba a la izquierda.
--
-- Antes el nombre iba sobre una chapa rectangular y el cambio no es de adorno:
-- la portada tiene que prometer lo que hay dentro, y lo que hay dentro es un
-- bol. Una chapa con el nombre grabado promete una placa; el mismo nombre en
-- la panza de un cacharro de acero es el bol de alguien, y ese alguien esta
-- justo encima mirandolo.

local Constants = require("src.constants")
local Palette   = require("src.palette")
local Session   = require("src.session")
local Arcade    = require("src.arcade")
local UI        = require("src.ui")
local Art       = require("src.art")
local Kiko      = require("src.kiko")
local Sfx       = require("src.sfx")
local ScreenManager = require("lib.screen_manager")

local Portada = {}

local NOMBRE = { "K", "I", "K", "O" }

local tiempo = 0

-- El perro de la portada, quieto: parpadea y levanta las orejas cada tres
-- segundos y pico, que es el mismo animo que tiene en la cabecera mientras la
-- partida va normal. No hay otro: en esta pantalla no esta pasando nada, y un
-- perro haciendo cosas en la puerta del juego prometeria una de ellas.
local perro = Kiko.nuevo()

function Portada.enter()
    tiempo = 0
end

function Portada.update(dt)
    tiempo = tiempo + dt
    perro:update(dt)
end

function Portada.keypressed(key)
    if key == "escape" then love.event.quit() end
end

-- El nombre, letra a letra y con el hueco a mano. "KIKO" con el espaciado de
-- la fuente deja las letras casi pegadas de dos en dos; separadas se leen como
-- cuatro letras estampadas, que es lo que es.
--
-- Del faldon cambia UNA cosa, y no es el desplazamiento. La copia clara se
-- queda en un pixel a la derecha y dos abajo, como alli: con la fuente grande
-- se probo a separarla mas (proporcional al cuerpo de la letra) y lo que sale
-- no es una letra mas hundida, es una letra CLARA con un canto oscuro --
-- desplazada cuatro pixeles, la copia de luz cubre media asta. La luz de una
-- incision es el filo de la ranura y el filo no crece con la letra.
--
-- Lo que si cambia es el color de la incision, que va tirada hacia la tinta en
-- vez del `metalDark` de siempre: una letra de sesenta y cuatro pixeles llena
-- de gris sobre un acero gris no tiene donde contrastar y lo unico que se lee
-- de ella acaba siendo el halo claro de debajo.
local function grabarNombre(cx, y, font)
    local hueco = math.floor(font:getHeight() * 0.45)
    local ancho = -hueco
    for _, l in ipairs(NOMBRE) do ancho = ancho + font:getWidth(l) + hueco end

    local incision = Palette.mix(Palette.metalDark, Palette.ink, 0.55)

    love.graphics.setFont(font)
    local x = math.floor(cx - ancho / 2)
    for _, l in ipairs(NOMBRE) do
        love.graphics.setColor(Palette.metalShine)
        love.graphics.print(l, x + 1, y + 2)
        love.graphics.setColor(incision)
        love.graphics.print(l, x, y)
        x = x + font:getWidth(l) + hueco
    end
    love.graphics.setColor(1, 1, 1, 1)
    return ancho
end

function Portada.draw()
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    local A = Constants.ART
    love.graphics.clear(Palette.uiBack)
    for k = 0, math.ceil(H / 96) do
        love.graphics.setColor(k % 2 == 0 and Palette.fondoAlt or Palette.fondo)
        love.graphics.rectangle("fill", 0, k * 96, W, 96)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- Kiko, al doble de la escala del tablero: es el mismo perro de la
    -- cabecera y tiene que reconocerse como el mismo pixel, solo que aqui es
    -- el protagonista y no un icono.
    local escala = A * 2
    local kw, kh = Art.size(perro:id())
    kw, kh = kw * escala, kh * escala

    -- El respingo: sube y baja UN pixel de arte, nunca medio. Es lo unico que
    -- se mueve en esta pantalla, y con medio pixel el perro se veria vibrar
    -- borroso en vez de respirar.
    local bote = math.floor(math.sin(tiempo * 2.2) * 1.4) * A

    -- Las dos puertas mandan en el reparto: se apoyan abajo, donde llega el
    -- pulgar, y lo que queda por encima es lo que hay para el perro y el
    -- nombre. El bloque se CENTRA en ese hueco en vez de colgar de arriba: el
    -- lienzo mide distinto en cada telefono (ver `Constants`), y colgado de
    -- arriba el aire sobrante se junta todo debajo del nombre.
    local bw = W - 96
    local bh = 88
    local by = H - Constants.SAFE_BOTTOM - bh * 2 - 22 - 70

    -- El bol va a la escala del tablero y no a la del perro: asi su pixel es
    -- el MISMO pixel que el del bol de dentro del juego, que es de lo que va
    -- toda esta pantalla. El perro va al doble porque es una cara y a escala
    -- de tablero no se le leerian los ojos.
    local font = Fonts.huge
    local bolW, bolH = Art.size("bol")
    bolW, bolH = bolW * A, bolH * A

    -- El perro pegado al bol, con el hueco justo: separados se leen como dos
    -- dibujos en la misma pantalla, y juntos se leen como un perro delante de
    -- su cacharro, que es la unica frase que tiene que decir la portada.
    local HUECO = 8
    local bloque = kh + HUECO + bolH + 10 + Fonts.small:getHeight()

    local yKiko = Constants.SAFE_TOP
                  + math.floor((by - Constants.SAFE_TOP - bloque) / 2 / A) * A
    perro:dibujar(W / 2 - kw / 2, yKiko + bote, escala)

    local yBol = yKiko + kh + HUECO
    love.graphics.draw(Art.get("bol"), math.floor(W / 2 - bolW / 2), math.floor(yBol),
                       0, A, A)

    -- El nombre, grabado en la PANZA. La altura es la del sprite: `PANZA` es la
    -- fila del bol (de sus 58) donde queda centrado el grabado, justo debajo
    -- del labio y donde el acero todavia es ancho. Mas abajo la panza se
    -- estrecha y la O se saldria por el canto; mas arriba se metería dentro de
    -- la boca, que es hueco y no acero.
    --
    -- El texto NO va dentro del scale del arte: es una fuente y ya viene en
    -- pixeles de pantalla, asi que metida en la rejilla del bol se
    -- multiplicaria por cuatro.
    local PANZA = 30
    grabarNombre(W / 2, yBol + PANZA * A - font:getHeight() / 2, font)

    UI.textoCentro("match-3 de galletas", W / 2, yBol + bolH + 10,
                   Palette.dim, Fonts.small)

    -- Las dos puertas. `bw`, `bh` e `by` se han medido arriba: son ellas las
    -- que dicen cuanto sitio le queda al perro.
    if UI.boton(W / 2 - bw / 2, by, bw, bh, "Niveles", { font = Fonts.large }) then
        Sfx.play("toque", 1.4)
        ScreenManager.switch("mapa")
    end
    if UI.boton(W / 2 - bw / 2, by + bh + 22, bw, bh, "Arcade",
                { tono = Palette.green, font = Fonts.large }) then
        Sfx.play("toque", 1.4)
        -- Una partida nueva cada vez que se entra: el arcade no se guarda a
        -- medias (ver `src/session.lua`), asi que este boton no puede prometer
        -- continuar nada.
        ScreenManager.switch("juego", 1, Arcade.nuevo(os.time()))
    end

    -- Debajo del boton, la marca. Solo si la hay: una linea que dice "ronda 0"
    -- le cuenta al que no ha jugado nunca que le falta algo.
    local marca = Session.arcade()
    if marca.ronda > 0 then
        UI.textoCentro(string.format("mejor: ronda %d  ·  %d puntos", marca.ronda, marca.puntos),
                       W / 2, by + bh * 2 + 34, Palette.dim, Fonts.tiny)
    end

    -- El sonido, en la esquina y con el mismo aspecto que en el mapa: es el
    -- unico ajuste del juego y esta en los dos sitios donde se puede tocar sin
    -- perder una partida. Mayusculas y letra de boton por lo que se explica
    -- alli; las dos puertas de aqui arriba no las llevan porque su letra mide
    -- 48 y ya se lee desde lejos.
    local sw, sh = 120, 48
    if UI.boton(W - sw - 14, Constants.SAFE_TOP + 12, sw, sh,
                Sfx.activo and "SONIDO" or "MUDO",
                { tono = Sfx.activo and Palette.green or Palette.uiLine, font = Fonts.small }) then
        Sfx.silenciar(Sfx.activo)
        Session.datos.sonido = Sfx.activo
        Session.save()
    end
end

return Portada
