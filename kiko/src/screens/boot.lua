-- El arranque: genera el arte con una barra de progreso.
--
-- El arte se genera por codigo (`src/art.lua`) y eso cuesta unas decimas: en
-- escritorio no se ve, en un movil de hace cinco anos si. Generarlo de un
-- tiron dejaria la pantalla en negro sin decir nada, que es lo que se lee como
-- "se ha colgado", asi que se pide un sprite por fotograma y entre uno y otro
-- se pinta la barra.

local Constants = require("src.constants")
local Palette   = require("src.palette")
local Art       = require("src.art")
local UI        = require("src.ui")
local Sfx       = require("src.sfx")
local Session   = require("src.session")
local ScreenManager = require("lib.screen_manager")

local Boot = {}

local progreso, listo, espera = 0, false, 0

function Boot.enter()
    progreso, listo, espera = 0, false, 0
end

function Boot.update(dt)
    if listo then
        -- Medio segundo de cortesia con la barra llena: sin el, en escritorio
        -- la pantalla de carga es un parpadeo y parece un fallo de dibujo.
        espera = espera + dt
        if espera > 0.4 then ScreenManager.switch("portada") end
        return
    end

    -- Varios por fotograma: a uno por fotograma y 32 sprites, el arranque
    -- duraria medio segundo en una pantalla de 60 Hz aunque la maquina pudiera
    -- hacerlo en dos centesimas.
    for _ = 1, 4 do
        local fin, p = Art.step()
        progreso = p
        if fin then
            listo = true
            Sfx.load()
            Session.load()
            Sfx.silenciar(not Session.datos.sonido)
            break
        end
    end
end

function Boot.draw()
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    love.graphics.clear(Palette.uiBack)

    UI.textoCentro("KIKO", W / 2, H / 2 - 120, Palette.gold, Fonts.huge)

    -- La misma barra que la del hambre en la cabecera (`UI.barraPixel`): es lo
    -- primero que se ve del juego y ya dice de que esta hecho todo lo demas.
    -- El canto si es distinto -- tinta y no `uiLine` --: aqui no hay nada mas
    -- en pantalla y la barra tiene que sostenerla ella sola.
    local u = Constants.ART
    local bw, bh = math.floor(W * 0.6 / u) * u, 6 * u
    local bx, by = math.floor((W - bw) / 2), math.floor(H / 2)
    UI.barraPixel(bx, by, bw, bh, u, progreso, {
        borde = Palette.ink, hueco = Palette.uiBack,
        base = Palette.gold, luz = Palette.goldLite, sombra = Palette.goldDark,
    })

    UI.textoCentro("llenando el bol...", W / 2, by + 34, Palette.dim, Fonts.tiny)

    -- Los sprites ya hechos van desfilando debajo de la barra: es la forma mas
    -- barata de que una pantalla de carga diga que esta haciendo algo, y de
    -- paso ensena el arte del juego antes de empezarlo.
    local s = 2
    local x = bx
    local y = by + 70
    for k = math.max(1, #Art.list - 12), #Art.list do
        local id = Art.list[k]
        local w = select(1, Art.size(id)) * s
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Art.get(id), math.floor(x), math.floor(y), 0, s, s)
        x = x + w + 4
    end
end

return Boot
