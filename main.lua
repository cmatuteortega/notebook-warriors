-- Notebook Survivors
--
-- Everything is rendered into a low-resolution canvas and then blown up by a
-- whole number, which is what keeps the art on a single consistent pixel grid:
-- one game pixel is always an exact square block of screen pixels, never
-- blurred or half a pixel off.
--
-- The canvas is not a fixed 320x180. The zoom is chosen from the screen, and
-- then the canvas is made exactly as many game pixels as it takes to cover the
-- window at that zoom. A 16:9 desktop window lands back on 320x180; a phone,
-- whatever shape its screen is, gets a canvas of that shape and fills it edge
-- to edge. Nothing is letterboxed and nothing is stretched -- a wider screen
-- shows more of the page, rather than the same page with bars around it.

local Game = require("src.game")
local Input = require("src.input")
local Palette = require("src.palette")

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

    -- Whole-number zoom only, taken off the short edge so the page is never
    -- shown at less than its design height: a bigger screen gets more page,
    -- never pixels smaller than they were drawn to be.
    scale = math.max(1, math.floor(math.min(w, h) / BASE_H))

    -- Enough game pixels to cover the window. The odd fraction of a pixel left
    -- over is split between opposite edges, so the offsets come out zero or
    -- barely negative and the canvas always reaches every corner.
    local cw, ch = math.ceil(w / scale), math.ceil(h / scale)
    if cw ~= vw or ch ~= vh or not canvas then
        vw, vh = cw, ch

        -- Dragging a window edge comes through here every frame, so the canvas
        -- being replaced is let go of rather than left for the collector.
        if canvas then canvas:release() end

        canvas = love.graphics.newCanvas(vw, vh)
        canvas:setFilter("nearest", "nearest")
        Game:resize(vw, vh)
    end

    offsetX = math.floor((w - vw * scale) / 2)
    offsetY = math.floor((h - vh * scale) / 2)

    -- Touches are reported in real screen pixels while the rest of the game
    -- works in window units. Identical unless DPI scaling is on, but carrying
    -- the ratio costs nothing and keeps the stick under the thumb if it ever is.
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
        -- Take the whole screen, system bars included. The safe insets are what
        -- then keeps the HUD out from under the notch.
        love.window.setFullscreen(true, "desktop")
        -- No mouse on a phone and no keyboard either, so show the stick from
        -- the first frame instead of waiting for a touch to reveal it.
        Input.usingTouch = true
    end

    fitToWindow()
    Game:load(vw, vh)
end

function love.resize()
    fitToWindow()
end

function love.focus(focused)
    -- Backgrounding the app swallows the touchreleased events, which would
    -- otherwise leave the stick jammed on and the pen drawing on its own.
    if not focused then Input.releaseAll() end
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

    -- The canvas covers the window, but clear underneath it in the darkest ink
    -- anyway: a stale frame showing through a rounding gap would read as a
    -- flicker along the edge.
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

love.mousepressed = Input.mousepressed
love.mousemoved = Input.mousemoved
love.mousereleased = Input.mousereleased
love.touchpressed = Input.touchpressed
love.touchmoved = Input.touchmoved
love.touchreleased = Input.touchreleased
