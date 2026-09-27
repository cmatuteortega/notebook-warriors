-- Kiko - match-3 de galletas.
--
-- main.lua se ocupa de cuatro cosas y ninguna mas: montar el lienzo virtual,
-- cargar las fuentes, repartir la entrada y llevar el reloj de los tweens.
-- Todo lo demas vive en src/.
--
-- El puntero se convierte a coordenadas virtuales UNA vez, aqui, y se pasa
-- tanto a la interfaz inmediata (src/ui.lua) como a la pantalla activa.
-- Ninguna pantalla toca coordenadas de ventana.

local Constants     = require("src.constants")
local Palette       = require("src.palette")
local Viewport      = require("lib.viewport")
local ScreenManager = require("lib.screen_manager")
local flux          = require("lib.flux")
local UI            = require("src.ui")
local Console       = require("src.console")
local Session       = require("src.session")

-- Antes que nada: a partir de aqui todo `print` queda tambien guardado para la
-- consola. Se engancha al cargar el modulo y no en love.load porque lo que mas
-- interesa leer -- que la sintesis de sonido no arranque, que un sprite falte
-- -- se imprime durante la carga, y en movil no hay terminal donde verlo.
Console.hook()

local BootScreen = require("src.screens.boot")
local PortadaScreen = require("src.screens.portada")
local MapaScreen = require("src.screens.mapa")
local MejorasScreen = require("src.screens.mejoras")
local JuegoScreen = require("src.screens.juego")

Fonts = {}

-- El resize se aplaza: arrastrar una ventana en escritorio dispara decenas de
-- eventos por segundo y recargar fuentes y lienzo en cada uno da tirones.
local pendiente, temporizador = nil, 0
local RETARDO = 0.1
local ultimoW, ultimoH = 0, 0

local function cargarFuentes()
    for nombre, tamano in pairs({ giant = Constants.FONT_SIZES.GIANT,
                                  huge = Constants.FONT_SIZES.HUGE,
                                  large = Constants.FONT_SIZES.LARGE,
                                  medium = Constants.FONT_SIZES.MEDIUM,
                                  small = Constants.FONT_SIZES.SMALL,
                                  tiny = Constants.FONT_SIZES.TINY }) do
        Fonts[nombre] = love.graphics.newFont("Pixellari.ttf", tamano)
        Fonts[nombre]:setFilter("nearest", "nearest")
    end
end

local function encajar(w, h)
    local sx, sy, sw, sh = 0, 0, w, h
    if love.window.getSafeArea then sx, sy, sw, sh = love.window.getSafeArea() end

    Constants.updateResolution(w, h)
    Constants.updateSafeInsets(sx, sy, sw, sh, w, h)
    cargarFuentes()
    Viewport.setup(Constants.GAME_WIDTH, Constants.GAME_HEIGHT, w, h)
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")

    local w, h = love.graphics.getDimensions()
    encajar(w, h)
    ultimoW, ultimoH = w, h

    ScreenManager.init({
        boot    = BootScreen,
        portada = PortadaScreen,
        mapa    = MapaScreen,
        mejoras = MejorasScreen,
        juego   = JuegoScreen,
    }, "boot")

    print(string.format("Kiko | ventana %dx%d | virtual %dx%d | arte %dx%d (x%d)",
                        w, h, Constants.GAME_WIDTH, Constants.GAME_HEIGHT,
                        Constants.ART_W, Constants.ART_H, Constants.ART))
end

function love.update(dt)
    if pendiente then
        temporizador = temporizador + dt
        if temporizador >= RETARDO then
            local w, h = pendiente.w, pendiente.h
            pendiente, temporizador = nil, 0
            if w ~= ultimoW or h ~= ultimoH then
                encajar(w, h)
                ultimoW, ultimoH = w, h
                ScreenManager.resize()
            end
        end
    end

    -- Los tweens se actualizan AQUI y en ningun otro sitio. flux lleva una
    -- lista global, asi que actualizarlo tambien desde una pantalla hace que
    -- todo corra al doble de velocidad -- y eso no se lee como un fallo de
    -- reloj, se lee como que las animaciones estan mal hechas.
    --
    -- Un dt enorme (la aplicacion vuelve de segundo plano en el movil) se
    -- recorta: sin el tope, todas las animaciones en vuelo terminan de golpe y
    -- el tablero aparece resuelto sin que se haya visto nada.
    flux.update(math.min(dt, 1 / 20))
    -- El reloj de los botones. No pasa por flux a proposito: lo que anima un
    -- boton es un contador que baja, no un tween con destino, y meterlo en la
    -- lista global obligaria a crear y tirar un tween por cada toque.
    UI.update(dt)
    ScreenManager.update(dt)
end

function love.draw()
    love.graphics.clear(Palette.ink)
    Viewport.start()
    ScreenManager.draw()
    UI.finish()          -- consume el toque de este fotograma
    -- La consola va DESPUES del finish y dentro del viewport: encima de todo,
    -- en coordenadas virtuales, y sin participar del toque del fotograma.
    Console.draw()
    Viewport.finish()
end

--== Entrada ===============================================================

-- Con la consola abierta el juego no ve ni un toque: el dedo sube y baja el
-- log y nada mas. Es lo que permite leer un error largo sin jugar sin querer.
local function press(x, y)
    x, y = Viewport.toGame(x, y)
    if not x then return end
    if Console.visible then Console.press(x, y) return end
    UI.press(x, y)
    ScreenManager.press(x, y)
end

local function move(x, y)
    x, y = Viewport.toGame(x, y)
    if not x then return end
    if Console.visible then Console.move(x, y) return end
    UI.move(x, y)
    ScreenManager.move(x, y)
end

local function release(x, y)
    x, y = Viewport.toGame(x, y)
    if not x then return end
    if Console.visible then Console.release(x, y) return end
    UI.release(x, y)
    ScreenManager.release(x, y)
end

function love.mousepressed(x, y, button, istouch)
    if istouch then return end   -- el tactil llega por su propio callback
    press(x, y)
end

function love.mousemoved(x, y, dx, dy, istouch)
    if istouch then return end
    move(x, y)
end

function love.mousereleased(x, y, button, istouch)
    if istouch then return end
    release(x, y)
end

-- Solo se atiende el primer dedo. Este juego no tiene ningun gesto de dos
-- dedos: el tablero no se acerca ni se arrastra, asi que el segundo dedo no
-- existe salvo para abrir la consola.
--
-- Un dedo puede dejar de existir SIN pasar por love.touchreleased -- lo
-- cancela el sistema, se lo come un gesto de la plataforma -- y un dedo
-- fantasma deja el juego MUDO para siempre, porque todo lo que llega con uno
-- ya puesto se descarta. Por eso lo primero que se hace al apoyar un dedo
-- nuevo es comprobar que el que teniamos apuntado sigue ahi.
local dedo = nil

local function sigueAhi(id)
    if id == nil then return false end
    for _, t in ipairs(love.touch.getTouches()) do
        if t == id then return true end
    end
    return false
end

function love.touchpressed(id, x, y)
    if not sigueAhi(dedo) then dedo = nil end

    -- Tres dedos a la vez abren y cierran la consola. Tres y no dos porque dos
    -- salen solos al agarrar el telefono.
    if #love.touch.getTouches() >= 3 then
        if dedo then
            -- El dedo que hubiera se suelta como ARRASTRE: asi no dispara el
            -- boton que tuviera debajo al desaparecer.
            UI.pointer.moved = true
            release(x, y)
            dedo = nil
        end
        Console.toggle()
        return
    end

    if dedo then return end
    dedo = id
    press(x, y)
end

function love.touchmoved(id, x, y)
    if id ~= dedo then return end
    move(x, y)
end

function love.touchreleased(id, x, y)
    if id ~= dedo then return end
    dedo = nil
    release(x, y)
end

function love.keypressed(key)
    if key == "f2" then
        Console.toggle()
        return
    end
    if key == "f11" or (key == "return" and love.keyboard.isDown("lalt", "ralt")) then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        local w, h = love.graphics.getDimensions()
        encajar(w, h)
        ultimoW, ultimoH = w, h
        return
    end
    ScreenManager.keypressed(key)
end

function love.resize(w, h)
    if w == ultimoW and h == ultimoH then return end
    pendiente, temporizador = { w = w, h = h }, 0
end

-- Guardar al perder el foco es lo que hace que el progreso cuadre en movil,
-- donde love.quit puede no ejecutarse nunca.
function love.focus(focused)
    if not focused then Session.save() end
end

function love.quit()
    Session.save()
end
