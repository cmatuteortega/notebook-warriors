-- La consola. En un movil no hay terminal, asi que el log va tambien en
-- pantalla: TRES DEDOS a la vez la abren y la cierran (en escritorio, F2).
--
-- Tres y no dos porque dos salen solos al agarrar el telefono. Es el sitio
-- donde mirar cuando algo se ve distinto en el movil, porque los fallos de
-- ahi son silenciosos: si la sintesis de sonido falla, el juego sigue mudo y
-- eso no se distingue de haberlo silenciado a proposito.

local Constants = require("src.constants")
local Palette   = require("src.palette")

local Console = {}

Console.visible = false

local lineas, TOPE = {}, 200
local scroll = 0
local arrastre = nil

local printOriginal = print

function Console.hook()
    print = function(...)
        printOriginal(...)
        local partes = {}
        for i = 1, select("#", ...) do partes[#partes + 1] = tostring(select(i, ...)) end
        lineas[#lineas + 1] = table.concat(partes, "  ")
        if #lineas > TOPE then table.remove(lineas, 1) end
    end
end

function Console.toggle()
    Console.visible = not Console.visible
    scroll = 0
end

function Console.press(x, y)
    arrastre = { y = y, scroll = scroll }
end

function Console.move(x, y)
    if not arrastre then return end
    scroll = math.max(0, arrastre.scroll + (y - arrastre.y))
end

function Console.release()
    arrastre = nil
end

function Console.draw()
    if not Console.visible then return end
    local W, H = Constants.GAME_WIDTH, Constants.GAME_HEIGHT
    love.graphics.setColor(Palette.ink[1], Palette.ink[2], Palette.ink[3], 0.93)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setFont(Fonts.tiny)
    local lh = Fonts.tiny:getHeight() + 2
    local y = H - Constants.SAFE_BOTTOM - lh * 2 + scroll
    for i = #lineas, 1, -1 do
        if y < -lh then break end
        if y < H then
            -- El velo de la consola es tinta, no panel: aqui el texto va en miga
    -- y no en `text`, que es marron oscuro y sobre el velo no se lee.
    love.graphics.setColor(Palette.miga)
            love.graphics.print(lineas[i], 8, y)
        end
        y = y - lh
    end

    love.graphics.setColor(Palette.gold)
    love.graphics.print("consola  ·  tres dedos para cerrar", 8, Constants.SAFE_TOP + 6)
    love.graphics.setColor(1, 1, 1, 1)
end

return Console
