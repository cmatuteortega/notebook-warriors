function love.conf(t)
    t.identity = "notebook-survivors"
    -- Naming the running engine is deliberate. The field does nothing but
    -- decide whether LOVE opens its "Compatibility Warning" box on mismatch,
    -- and this ships on two engines -- 11.x on desktop, 12.0 in the Android
    -- build -- so any literal would box one of them. LuaJIT/5.1 on both.
    t.version = love._version
    t.console = false

    t.window.title = "Survive School"
    t.window.width = 1280
    t.window.height = 720
    t.window.minwidth = 320
    t.window.minheight = 180
    t.window.resizable = true
    t.window.vsync = 1

    -- No DPI scaling: a game pixel must land on a whole number of screen pixels
    -- or the art smears, and touches then arrive in the units the game draws in.
    t.window.highdpi = false
    t.window.usedpiscale = false

    -- love.system does not exist yet here, so the phone window setup
    -- (fullscreen, edge to edge) happens in love.load instead.

    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    -- Off, the touch callbacks never fire: a phone with no controls at all.
    t.modules.touch = true
end
