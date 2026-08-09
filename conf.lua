function love.conf(t)
    t.identity = "notebook-survivors"
    t.version = "11.4"
    t.console = false

    t.window.title = "Notebook Survivors"
    t.window.width = 1280
    t.window.height = 720
    t.window.minwidth = 320
    t.window.minheight = 180
    t.window.resizable = true
    t.window.vsync = 1

    -- No DPI scaling anywhere. One game pixel has to land on a whole number of
    -- screen pixels or the art smears, and it also keeps touches in the same
    -- units the game draws in, which is what puts the thumb stick under the
    -- thumb instead of half a screen away from it.
    t.window.highdpi = false
    t.window.usedpiscale = false

    -- love.system does not exist yet while this file runs, so the phone window
    -- setup (fullscreen, edge to edge) is done in love.load instead.

    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    -- Touch stays on. With it off the touch callbacks never fire at all, which
    -- leaves a phone with no controls whatsoever.
    t.modules.touch = true
end
