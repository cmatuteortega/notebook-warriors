-- Drawn in canvas space (no camera transform) so it stays crisp on the grid.
--
-- Every position here is measured off the safe area rather than the canvas
-- edge, so nothing ends up under a notch or a gesture bar on a phone.

local Palette = require("src.palette")
local Font = require("src.font")
local Sprites = require("src.sprites")
local Tools = require("src.tools")
local Input = require("src.input")
local pixelart = require("src.pixelart")

local Hud = {}

-- Tool selector: a stack of boxes down the right edge, with the ink gauge
-- running alongside it.
local SEL_SIZE, SEL_GAP = 13, 3
local SEL_MARGIN = 4          -- from the right edge of the safe area
local SEL_POP = 3             -- how far the selected tool slides out
local GAUGE_W, GAUGE_GAP = 3, 4
local PITCH = SEL_SIZE + SEL_GAP

-- Pause button: the top-left corner of the safe area, off the same 4px margin
-- the readouts use, with the health bar starting to the right of it. The whole
-- of the right margin belongs to the tool column, which is nine tools tall and
-- has nothing to spare; the bottom-left corner belongs to the thumb stick. This
-- is the one corner with room in it.
local PAUSE_SIZE = 11
local PAUSE_MARGIN = 4

-- A finger is a lot bigger and a lot blinder than a mouse pointer, so the
-- touch target reaches further out from the boxes than the mouse one does.
local function selectorPad()
    if Input.usingTouch then return 11, 6 end
    return 4, 2
end

-- The same allowance for the pause button, which shares this edge.
local function pausePad()
    return Input.usingTouch and 5 or 2
end

local function pauseBox(game)
    return game.inset.l + PAUSE_MARGIN, game.inset.t + PAUSE_MARGIN
end

local function selectorX(game)
    return game.vw - game.inset.r - SEL_MARGIN - SEL_SIZE
end

-- Centred on the page. The right margin is the column's alone -- nothing else
-- is drawn in it and nothing else tests a press there -- so it can have all of
-- it and sit in the middle of it.
local function selectorTop(game)
    local total = #Tools.list * PITCH - SEL_GAP
    local mid = game.inset.t + (game.vh - game.inset.t - game.inset.b) / 2
    return math.floor(mid - total / 2)
end

local function selectorY(game, index)
    return selectorTop(game) + (index - 1) * PITCH
end

-- Which tool, if any, is under a canvas-space point. Returns nil for a miss.
--
-- The strip is treated as one continuous column rather than six separate
-- boxes: each tool owns its box plus the gap under it, so a press that lands
-- between two of them picks one instead of doing nothing. On a phone that is
-- the difference between a selector that works and one you have to aim at.
function Hud.selectorAt(game, cx, cy)
    local padX, padY = selectorPad()
    if cx < selectorX(game) - SEL_POP - padX then return nil end

    local top = selectorTop(game)
    local total = #Tools.list * PITCH - SEL_GAP
    if cy < top - padY or cy > top + total + padY then return nil end

    local index = math.floor((cy - top) / PITCH) + 1
    return math.max(1, math.min(#Tools.list, index))
end

-- Whether a canvas-space point presses the pause button. Same reasoning as the
-- selector: a finger needs more room around it than a mouse pointer does.
function Hud.pauseAt(game, cx, cy)
    local pad = pausePad()
    local x, y = pauseBox(game)
    return cx >= x - pad and cx <= x + PAUSE_SIZE + pad
       and cy >= y - pad and cy <= y + PAUSE_SIZE + pad
end

--- pieces --------------------------------------------------------------------

local function drawStick()
    if not Input.usingTouch then return end

    local ox, oy, kx, ky, active = Input.stickState()

    -- The ring is a pencil circle on the page; the knob is a drawn blob that
    -- takes the player's red once you have hold of it.
    love.graphics.setColor(Palette.graphite)
    pixelart.circleOutline(ox, oy, Input.STICK_R)
    love.graphics.setColor(active and Palette.blush or Palette.paper)
    pixelart.circleFill(kx, ky, Input.KNOB_R)
    love.graphics.setColor(active and Palette.red or Palette.slate)
    pixelart.circleOutline(kx, ky, Input.KNOB_R)
end

-- The same box the tool selector draws, one size down: it belongs to the same
-- set of things you press. Red while the run is held, so the frozen page has an
-- obvious way out of it.
local function drawPause(game)
    local x, y = pauseBox(game)
    local paused = game.state == "paused"

    love.graphics.setColor(paused and Palette.red or Palette.slate)
    love.graphics.rectangle("fill", x, y, PAUSE_SIZE, PAUSE_SIZE)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, PAUSE_SIZE - 2, PAUSE_SIZE - 2)

    love.graphics.setColor(1, 1, 1)
    Sprites.icons[paused and "play" or "pause"]
        :draw(x + PAUSE_SIZE / 2, y + PAUSE_SIZE / 2)
end

local function drawSelector(game)
    local baseX = selectorX(game)

    for i, tool in ipairs(Tools.list) do
        local selected = i == game.tool
        local x = baseX - (selected and SEL_POP or 0)
        local y = selectorY(game, i)

        love.graphics.setColor(selected and Palette.red or Palette.slate)
        love.graphics.rectangle("fill", x, y, SEL_SIZE, SEL_SIZE)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, y + 1, SEL_SIZE - 2, SEL_SIZE - 2)

        love.graphics.setColor(1, 1, 1)
        Sprites.icons[tool.icon]:draw(x + SEL_SIZE / 2, y + SEL_SIZE / 2)
    end

    -- Ink gauge, filling from the bottom.
    local gx = baseX - SEL_POP - GAUGE_GAP - GAUGE_W
    local gy = selectorY(game, 1)
    local gh = selectorY(game, #Tools.list) + SEL_SIZE - gy

    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", gx, gy, GAUGE_W, gh)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", gx + 1, gy + 1, GAUGE_W - 2, gh - 2)

    local fill = math.floor((gh - 2) * game.ink)
    if fill > 0 then
        local low = game.ink < Tools.MIN_INK
        love.graphics.setColor(low and Palette.blush or Palette.blue)
        love.graphics.rectangle("fill", gx + 1, gy + gh - 1 - fill, GAUGE_W - 2, fill)
    end
end

local function bar(x, y, w, h, fill, color)
    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)
    local inner = math.floor((w - 2) * math.max(0, math.min(1, fill)))
    if inner > 0 then
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x + 1, y + 1, inner, h - 2)
    end
end

local function clock(t)
    return ("%d:%02d"):format(math.floor(t / 60), math.floor(t % 60))
end

function Hud.draw(game)
    local vw, vh = game.vw, game.vh
    local ins = game.inset
    local player = game.player
    local top = ins.t + 4
    local centre = ins.l + (vw - ins.l - ins.r) / 2

    -- The safe left margin, and where the top row starts: the corner itself
    -- belongs to the pause button now, so everything sharing that row begins
    -- clear of it. The bottom-left readouts do not move -- that corner is the
    -- thumb stick's on touch and nobody's on desktop.
    -- Six, not four: the button's touch target reaches five pixels past its own
    -- box, and a health bar with the button's grab zone lying across its left
    -- end is a bar that pauses the run when you press it.
    local edge = ins.l + 4
    local left = edge + PAUSE_SIZE + 6

    -- Health, top left, beside the button.
    bar(left, top, 60, 6, player.hp / player.maxHp, Palette.red)
    love.graphics.setColor(Palette.ink)
    Font.print(("%d"):format(player.hp), left + 64, top + 1)

    -- Run timer, top centre.
    Font.printCentered(clock(game.time), centre, top + 1)

    -- Kills, top right.
    Font.printRight("KILLS " .. game.kills, vw - ins.r - 4, top + 1)

    -- Level and experience. Bottom left on desktop, but that corner belongs to
    -- the thumb stick on a phone, so there it tucks in under the health bar.
    if Input.usingTouch then
        bar(left, top + 8, 60, 4, player.xp / player.xpNext, Palette.blue)
        love.graphics.setColor(Palette.ink)
        Font.print("LV " .. player.level, left + 64, top + 8)
    else
        love.graphics.setColor(Palette.ink)
        Font.print("LV " .. player.level, edge, vh - ins.b - 12)
        bar(edge, vh - ins.b - 6, 60, 4, player.xp / player.xpNext, Palette.blue)
    end

    -- The stick is taken away while the run is held -- the whole page answers
    -- the pause card, corner included -- so it is not drawn either.
    if game.state ~= "paused" then drawStick() end
    drawSelector(game)

    -- Nothing to hold once the run is over; that corner goes back to the page.
    if game.state ~= "dead" then drawPause(game) end

    -- Name of the tool you just switched to, fading out.
    if game.toolLabel > 0 then
        love.graphics.setColor(game.toolLabel > 0.25 and Palette.slate or Palette.graphite)
        Font.printCentered(Tools.get(game.tool).name, centre, vh - ins.b - 14)
    end

    if game.state == "dead" then
        local w, h = 92, 30
        local x = math.floor(centre - w / 2)
        local y = math.floor(ins.t + (vh - ins.t - ins.b - h) / 2)

        love.graphics.setColor(Palette.ink)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)
        love.graphics.setColor(Palette.blush)
        love.graphics.rectangle("fill", x + 1, y + 1, w - 2, 1)

        love.graphics.setColor(Palette.red)
        Font.printCentered("GAME OVER", centre, y + 7)
        love.graphics.setColor(Palette.slate)
        Font.printCentered(clock(game.time) .. "  " .. game.kills .. " KILLS", centre, y + 15)
        love.graphics.setColor(Palette.ink)
        Font.printCentered(Input.usingTouch and "TAP TO RESTART" or "PRESS R", centre, y + 22)
    end
end

return Hud
