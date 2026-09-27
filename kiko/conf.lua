-- Kiko - match-3 de galletas en formato vertical (movil).
--
-- La ventana base es 540x960 como en Rumbo: el arte son sprites de 16px
-- dibujados a escala entera 4x, asi que el area de juego son ~135x240 pixeles
-- de arte y el tablero de 8x8 ocupa 128 de esos 135. Ver src/constants.lua.

function love.conf(t)
    t.identity = "kiko"

    -- La version de LOVE para la que se declara el juego. No cambia el
    -- comportamiento de nada: el boot.lua de LOVE solo la compara con la que
    -- esta corriendo y, si no casan, planta un cartel de aviso delante del
    -- juego antes de abrir la ventana. Un numero escrito aqui no puede casar,
    -- porque son DOS: el escritorio va con LOVE 11.5 y el APK de Android
    -- lleva LOVE 12 dentro. Asi que se lee del interprete, que es lo mismo
    -- que hace LOVE cuando no se dice nada (`version = love._version`, en su
    -- propio boot.lua). Es seguro porque las llamadas que usa el juego
    -- existen en las dos versiones: estan comprobadas una a una.
    t.version = love._version

    t.console = false
    t.accelerometerjoystick = false
    t.externalstorage = false

    -- Sin correccion de gamma. El campo cambio de sitio en LOVE 12 (se fue
    -- dentro de `t.graphics`) y en LOVE 11 vive suelto, asi que se escribe en
    -- el que exista: suelto en LOVE 12 todavia se obedece, pero deja un aviso
    -- de obsoleto en cada arranque.
    --
    -- Y se escribe el CAMPO, nunca la tabla entera. `t.graphics` llega con
    -- mas cosas dentro y LOVE las da por puestas: sustituirla deja
    -- `lowpower` a nil, boot.lua se lo pasa igual a `_setLowPowerPreferred`,
    -- que exige un booleano de verdad, y el error salta dentro de love.init,
    -- antes de que exista una ventana donde enseñarlo. En el telefono eso no
    -- se ve como un error: se ve como que la aplicacion no abre. Y en
    -- escritorio no se reproduce, porque LOVE 11 no mira `t.graphics`.
    if t.graphics then
        t.graphics.gammacorrect = false      -- LOVE 12
    else
        t.gammacorrect = false               -- LOVE 11
    end

    t.audio.mic = false
    t.audio.mixwithsystem = true

    t.window.title = "Kiko"
    t.window.icon = nil
    t.window.width = 540
    t.window.height = 960
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 270
    t.window.minheight = 480
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.msaa = 0
    t.window.highdpi = false     -- pixel perfecto: sin escalado de DPI
    t.window.usedpiscale = false

    -- En movil bloqueamos vertical y vamos a pantalla completa.
    if love.system and love.system.getOS then
        local os = love.system.getOS()
        if os == "Android" or os == "iOS" then
            t.window.orientation = "portrait"
            t.window.fullscreen = true
            t.window.fullscreentype = "desktop"
        end
    end

    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = false
    t.modules.window = true
end
