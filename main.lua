-- Survive School. Everything renders into a low-res canvas blown up by a
-- whole number, so a game pixel is always an exact block of screen pixels. The
-- canvas is not a fixed 320x180: zoom is picked off the SHORT window edge and
-- the canvas made as many game pixels as it takes to cover the window (320x180
-- on 16:9, 400x180 on a 20:9 phone, 180x400 upright). Nothing is letterboxed or
-- stretched, so a phone may turn (src/orient.lua) and screens lay themselves
-- out against `Game.vw/vh`.

local Game = require("src.game")
local Input = require("src.input")
local Orient = require("src.orient")
local Palette = require("src.palette")
local Sfx = require("src.sfx")

local BASE_H = 180  -- design height, in game pixels

local canvas
local vw, vh = 320, 180
local scale, offsetX, offsetY = 1, 0, 0

local function isMobile()
    local os = love.system.getOS()
    return os == "Android" or os == "iOS"
end

-- Notches, punch-holes and gesture bars. Reported in window units, wanted in
-- canvas pixels, as a margin off each edge for the HUD to keep clear of.
local function safeInsets()
    if not love.window.getSafeArea then return 0, 0, 0, 0 end

    local sx, sy, sw, sh = love.window.getSafeArea()
    local left = (sx - offsetX) / scale
    local top = (sy - offsetY) / scale

    return math.max(0, math.floor(left)),
           math.max(0, math.floor(top)),
           math.max(0, math.ceil(vw - (left + sw / scale))),
           math.max(0, math.ceil(vh - (top + sh / scale)))
end

local function fitToWindow()
    local w, h = love.graphics.getDimensions()

    -- Whole-number zoom off the SHORT edge, never below the design height: a
    -- bigger screen gets more page, not smaller pixels.
    scale = math.max(1, math.floor(math.min(w, h) / BASE_H))

    -- Enough game pixels to cover the window; the leftover fraction is split
    -- between opposite edges, so the canvas always reaches every corner.
    local cw, ch = math.ceil(w / scale), math.ceil(h / scale)
    if cw ~= vw or ch ~= vh or not canvas then
        vw, vh = cw, ch

        -- A dragged window edge lands here every frame: release, don't collect.
        if canvas then canvas:release() end

        canvas = love.graphics.newCanvas(vw, vh)
        canvas:setFilter("nearest", "nearest")
        Game:resize(vw, vh)
    end

    offsetX = math.floor((w - vw * scale) / 2)
    offsetY = math.floor((h - vh * scale) / 2)

    -- Touches report in real screen pixels, the game in window units; identical
    -- unless DPI scaling is on.
    local touchScale = 1
    if love.graphics.getPixelWidth then
        local pw = love.graphics.getPixelWidth()
        if pw and pw > 0 and w > 0 then touchScale = pw / w end
    end

    -- Input reports in canvas pixels, so it needs the same transform.
    Input.setTransform(scale, offsetX, offsetY, vw, vh, touchScale)

    local l, t, r, b = safeInsets()
    Input.setSafeInsets(l, t, r, b)
    Game:setSafeInsets(l, t, r, b)
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")

    if isMobile() then
        -- Whole screen, bars included; the safe insets keep the HUD off notches.
        love.window.setFullscreen(true, "desktop")
        -- No mouse or keyboard on a phone: show the stick from the first frame.
        Input.usingTouch = true
    end

    fitToWindow()
    Game:load(vw, vh)

    -- After Game:load, which reads the pinned mode off disk (src/options.lua),
    -- and here because turning the phone is a window call; the turn comes back
    -- a frame or two later as an ordinary resize.
    Orient.apply()
end

function love.resize()
    fitToWindow()
end

function love.focus(focused)
    -- Backgrounding swallows touchreleased: the stick jams on, the pen draws on.
    if not focused then Input.releaseAll() end
end

-- Out of sight, so silent (src/sfx.lua) and put down -- in that order, or the
-- pause card's sound is started at the last moment and replays as a stutter on
-- the way back in. Deliberately not love.focus: a run you can see you should be
-- able to hear. Android blocks the program while backgrounded, so this lands on
-- the way in and the music is stopped down in the engine.
function love.visible(visible)
    if visible then
        Sfx.resume()
    else
        Sfx.silence()
        Game:putDown()
    end
end

function love.update(dt)
    -- Clamp so a hitched frame can't teleport anything through a collision.
    Game:update(math.min(dt, 1 / 30))
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(Palette.paper)
    Game:draw()
    love.graphics.setCanvas()

    -- Darkest ink under the canvas: a stale frame showing through a rounding
    -- gap would read as a flicker along the edge.
    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f11" or (key == "return" and love.keyboard.isDown("lalt", "ralt")) then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        fitToWindow()
    else
        Game:keypressed(key)
    end
end

function love.wheelmoved(_, dy)
    Game:wheelmoved(dy)
end

-- Esc, the close button and the title screen's NO all land here: the last
-- chance to leave a bookmark (src/bookmark.lua). A force quit or crash misses
-- it -- a bookmark is what a deliberate exit leaves behind.
function love.quit()
    Game:closing()
end

love.mousepressed = Input.mousepressed
love.mousemoved = Input.mousemoved
love.mousereleased = Input.mousereleased
love.touchpressed = Input.touchpressed
love.touchmoved = Input.touchmoved
love.touchreleased = Input.touchreleased
