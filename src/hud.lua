-- Drawn in canvas space (no camera transform) so it stays crisp on the grid.
--
-- Every position here is measured off the safe area rather than the canvas
-- edge, so nothing ends up under a notch or a gesture bar on a phone.

local Palette = require("src.palette")
local Font = require("src.font")
local Sprites = require("src.sprites")
local Tools = require("src.tools")
local Upgrades = require("src.upgrades")
local Input = require("src.input")
local pixelart = require("src.pixelart")

local Hud = {}

-- Tool selector: a stack of boxes down the right edge, one per tool this run has
-- unlocked. Three at the most, and one at the start -- the strip is drafted, not
-- issued (src/loadout.lua).
local SEL_SIZE, SEL_GAP = 13, 3
local SEL_MARGIN = 4          -- from the right edge of the safe area
local SEL_POP = 3             -- how far the selected tool slides out
local COLUMN_GAP = 4          -- clearance a margin column keeps from the page
local PITCH = SEL_SIZE + SEL_GAP

-- A box to the level beside it. Both margin columns put a level next to a box
-- and both measure their width off this, which is what keeps them mirror images
-- of each other rather than two columns that happen to look similar.
local CARRY_LEVEL_GAP = 2

local function levelText(level)
    return tostring(level)
end

-- The two readout bars at the ends of the top row, health and ink. Same size,
-- because they are the same kind of thing read the same way; the experience bar
-- underneath is thinner, being the one you never have to watch.
local BAR_W, BAR_H = 60, 6
local BAR_TEXT_GAP = 4        -- bar to the number beside it

-- Pause button: the top-left corner of the safe area, off the same 4px margin
-- the readouts use, with the health bar starting to the right of it. The whole
-- of the right margin belongs to the tool column, which is claimed at its full
-- width whether the run has one tool in it or three; the bottom-left corner
-- belongs to the thumb stick. This is the one corner with room in it.
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

-- Everything the tool column claims off the right of the safe area: the boxes,
-- the pop of the selected one, and the level that appears beside them while the
-- run is held. A screen that wants to lay something out across the page (the
-- draft, src/levelup.lua) asks for this rather than guessing, because anything
-- under this column is something you can only see part of.
--
-- The room for the level is claimed all the time, though it is only drawn some
-- of the time, for the same reason the left margin is claimed while it is empty:
-- a margin that grows the moment a card is drawn on it is a margin that moves
-- the cards out from under the pointer about to circle one.
function Hud.rightMargin()
    return SEL_MARGIN + SEL_SIZE + SEL_POP
         + CARRY_LEVEL_GAP + Font.width("8") + COLUMN_GAP
end

-- Centred on the page. A margin belongs to its column alone -- nothing else is
-- drawn in it and nothing else tests a press there -- so it can have all of it
-- and sit in the middle of it. Both columns are struck off the same midline,
-- which is what makes the pair read as a pair.
local function columnTop(game, count)
    local total = count * PITCH - SEL_GAP
    local mid = game.inset.t + (game.vh - game.inset.t - game.inset.b) / 2
    return math.floor(mid - total / 2)
end

-- How many boxes there are to draw and to press: what this run has unlocked, not
-- what the game has to offer. The column grows as a run drafts tools, so it is
-- measured every time rather than being a constant.
local function equippedCount(game)
    return game.loadout and #game.loadout.equipped or 0
end

local function selectorTop(game)
    return columnTop(game, equippedCount(game))
end

local function selectorY(game, index)
    return selectorTop(game) + (index - 1) * PITCH
end

-- Which tool, if any, is under a canvas-space point. Returns nil for a miss.
--
-- The strip is treated as one continuous column rather than as separate boxes:
-- each tool owns its box plus the gap under it, so a press that lands between
-- two of them picks one instead of doing nothing. On a phone that is the
-- difference between a selector that works and one you have to aim at.
function Hud.selectorAt(game, cx, cy)
    local n = equippedCount(game)
    if n == 0 then return nil end

    local padX, padY = selectorPad()
    if cx < selectorX(game) - SEL_POP - padX then return nil end

    local top = selectorTop(game)
    local total = n * PITCH - SEL_GAP
    if cy < top - padY or cy > top + total + padY then return nil end

    local index = math.floor((cy - top) / PITCH) + 1
    return math.max(1, math.min(n, index))
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
    local loadout = game.loadout
    if not loadout then return end

    local baseX = selectorX(game)

    -- What level each tool has reached, but only while the run is held -- the
    -- same rule the weapon column opposite follows, and for the same reason:
    -- mid-run the page is the thing you are reading, and a number in the margin
    -- is a number in the way. The moment the run stops is the moment you want to
    -- know, and it is also the only moment the two columns are read as a pair.
    local held = game.state == "paused" or game.state == "levelup"

    for i, slot in ipairs(loadout.equipped) do
        local selected = i == game.tool
        local x = baseX - (selected and SEL_POP or 0)
        local y = selectorY(game, i)

        love.graphics.setColor(selected and Palette.red or Palette.slate)
        love.graphics.rectangle("fill", x, y, SEL_SIZE, SEL_SIZE)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, y + 1, SEL_SIZE - 2, SEL_SIZE - 2)

        love.graphics.setColor(1, 1, 1)
        Sprites.icons[slot.tool.icon]:draw(x + SEL_SIZE / 2, y + SEL_SIZE / 2)

        -- Hung off the inside edge of the box, where the weapon column hangs its
        -- levels off the outside edge of its own: both read outwards from the
        -- page rather than both reading left to right.
        if held then
            love.graphics.setColor(Palette.slate)
            Font.printRight(levelText(slot.level), x - CARRY_LEVEL_GAP,
                y + math.floor((SEL_SIZE - Font.height) / 2))
        end
    end
end

--- what the run is carrying ---------------------------------------------------

-- Only ever drawn while the run is held -- the pause screen and the draft --
-- and never during play. Mid-run the page is the thing you are reading, and
-- every pixel of margin spent on a summary of what you have is a pixel of it
-- you cannot see; the moment the run stops is exactly the moment you want to
-- know. Both screens draw it, so it lives here with the rest of the furniture
-- rather than twice over in two screens that only happen to agree.
--
-- The weapons go down the left margin in the same boxes, at the same size and
-- struck off the same midline as the tools down the right, because the two
-- columns are the two halves of what a run is made of: what you draw with, and
-- what draws for you. Everything else it has learned is not a thing it carries
-- so much as a thing it *is*, so it goes in one line under the question rather
-- than in a column of its own.
--
-- All three sets of icons are drawn in the same box, because a page this busy
-- can't be read against: a bare icon over a horde is a shape with a horde
-- behind it, and the box's paper fill is what makes it a thing on the page
-- instead. Only the levels are placed differently. A weapon's sits beside its
-- box, so the column stays exactly as tall as the tool column it mirrors; a
-- passive's sits on top of its own, where a line of them has all the height it
-- wants and no alignment to keep.
-- CARRY_LEVEL_GAP lives up with the selector constants: both columns use it.
local CARRY_NUM_GAP = 1    -- a passive's level to the box under it
local CARRY_GAP = 5        -- one passive to the next along the line

-- Everything of one kind the run has taken, in the order it was first picked up,
-- which is the only order any of this has.
--
-- One kind at a time rather than weapons-and-everything-else, because there are
-- three places a line can be shown and each takes exactly one kind: weapons down
-- the left, passives in the row under the question, and tools in the selector
-- column down the right, which draws itself. A tool shown in the passive row as
-- well would be the same tool twice on one screen -- and eight icons on a line
-- sized for five would run off the edge of a page held upright.
local function eachCarried(game, kind, fn)
    local loadout = game.loadout
    if not loadout then return end

    for _, id in ipairs(loadout.order) do
        local up = Upgrades.byId[id]
        if up.kind == kind then
            fn(up, loadout:levelOf(id))
        end
    end
end

local function carriedCount(game, kind)
    local n = 0
    eachCarried(game, kind, function() n = n + 1 end)
    return n
end

-- What the weapon column claims off the left of the safe area, whether there is
-- anything in it yet or not -- the mirror of Hud.rightMargin, and kept as fixed
-- as that one is.
--
-- It would be free to hand the width back while the column is empty, and it is
-- deliberately not: the cards would then be wider on the drafts before your
-- first weapon than on the ones after it, and the layout would rearrange itself
-- underneath the thing you were about to circle on the one draft you were
-- guaranteed to be looking at it. A margin that is only sometimes there is worse
-- than a margin.
function Hud.leftMargin()
    return SEL_MARGIN + SEL_SIZE + CARRY_LEVEL_GAP + Font.width("8") + COLUMN_GAP
end

-- The height the line of passives needs -- a level and the box under it -- or
-- nothing when there is none, so a screen can leave room for it in its stack
-- before it lays anything out.
function Hud.passiveRow(game)
    if carriedCount(game, "passive") == 0 then return 0 end
    return Font.height + CARRY_NUM_GAP + SEL_SIZE
end

local function passiveWidth(game)
    local n = carriedCount(game, "passive")
    if n == 0 then return 0 end
    return n * SEL_SIZE + (n - 1) * CARRY_GAP
end

function Hud.drawWeapons(game)
    local top = columnTop(game, carriedCount(game, "weapon"))
    local x = game.inset.l + SEL_MARGIN
    local i = 0

    eachCarried(game, "weapon", function(up, level)
        local y = top + i * PITCH
        i = i + 1

        -- The tool selector's box exactly, minus the pop and the red: nothing
        -- here is selected, because none of it is something you pick up.
        love.graphics.setColor(Palette.slate)
        love.graphics.rectangle("fill", x, y, SEL_SIZE, SEL_SIZE)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, y + 1, SEL_SIZE - 2, SEL_SIZE - 2)

        love.graphics.setColor(1, 1, 1)
        Sprites.icons[up.icon]:draw(x + SEL_SIZE / 2, y + SEL_SIZE / 2)

        love.graphics.setColor(Palette.slate)
        Font.print(levelText(level), x + SEL_SIZE + CARRY_LEVEL_GAP,
            y + math.floor((SEL_SIZE - Font.height) / 2))
    end)
end

-- Centred on cx, with the levels' tops at y and the boxes under them.
function Hud.drawPassives(game, cx, y)
    local total = passiveWidth(game)
    if total == 0 then return end

    local x = math.floor(cx - total / 2)
    local boxY = y + Font.height + CARRY_NUM_GAP

    eachCarried(game, "passive", function(up, level)
        local text = levelText(level)
        love.graphics.setColor(Palette.slate)
        Font.print(text, x + math.floor((SEL_SIZE - Font.width(text)) / 2), y)

        love.graphics.setColor(Palette.slate)
        love.graphics.rectangle("fill", x, boxY, SEL_SIZE, SEL_SIZE)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, boxY + 1, SEL_SIZE - 2, SEL_SIZE - 2)

        love.graphics.setColor(1, 1, 1)
        Sprites.icons[up.icon]:draw(x + SEL_SIZE / 2, boxY + SEL_SIZE / 2)

        x = x + SEL_SIZE + CARRY_GAP
    end)
end

--- readouts ------------------------------------------------------------------

-- `fromRight` hangs the fill off the far end instead of the near one, for the
-- bar in the right-hand corner: what makes the pair read as one row rather than
-- two of the same readout is that both are anchored to the edge of the page
-- they sit in and both empty towards the middle.
local function bar(x, y, w, h, fill, color, fromRight)
    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)
    local inner = math.floor((w - 2) * math.max(0, math.min(1, fill)))
    if inner > 0 then
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", fromRight and x + w - 1 - inner or x + 1,
            y + 1, inner, h - 2)
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
    local right = vw - ins.r - 4

    -- What you have and what you can spend, in the two top corners: the same
    -- bar at the same size, each hung off its own edge of the page with its
    -- number on the inside. The ink meter used to be a thin gauge stood on end
    -- beside the tool column, which is where you look to *change* tool and not
    -- where you look mid-stroke; as the health bar's mirror image it is read
    -- the way the health bar is read, at a glance, from the length of it.
    bar(left, top, BAR_W, BAR_H, player.hp / player.maxHp, Palette.red)
    love.graphics.setColor(Palette.ink)
    Font.print(("%d"):format(player.hp), left + BAR_W + BAR_TEXT_GAP, top + 1)

    -- Blush once there is too little left to start a stroke with: that is the
    -- one thing about the meter you have to catch without reading it. The floor
    -- is an absolute amount of ink rather than a fraction of the well, so an
    -- inkwell run goes blush further down the bar -- what it takes to start a
    -- line does not change because you can carry more.
    --
    -- The bar is how full the well is and the number beside it is how much is
    -- actually in it, which is why the number can read past 100. That is the
    -- health bar's arrangement exactly, and the two are drawn as mirror images
    -- of each other: a fresh page grows the health bar's maximum the same way an
    -- inkwell grows this one's, and both are read at a glance off the length.
    local inkX = right - BAR_W
    bar(inkX, top, BAR_W, BAR_H, game.ink / game.loadout.stats.inkMax,
        game.ink < Tools.MIN_INK and Palette.blush or Palette.blue, true)
    love.graphics.setColor(Palette.ink)
    Font.printRight(("%d"):format(game.ink * 100), inkX - BAR_TEXT_GAP, top + 1)

    -- Run timer, top centre.
    Font.printCentered(clock(game.time), centre, top + 1)

    -- Kills, bottom centre, on the timer's midline: the two of them are the
    -- score, they are read together on the game over card, and the top corners
    -- are both bars now. Nothing is in the way down here -- the bottom-left is
    -- the thumb stick's and the middle of that edge is nobody's. Seven, not six,
    -- so its foot lands on the same line as the experience bar's along the same
    -- edge: the glyphs are a pixel taller than the bar is.
    love.graphics.setColor(Palette.ink)
    Font.printCentered("KILLS " .. game.kills, centre, vh - ins.b - 7)

    -- Level and experience. Bottom left on desktop, but that corner belongs to
    -- the thumb stick on a phone, so there it tucks in under the health bar.
    if Input.usingTouch then
        bar(left, top + 8, BAR_W, 4, player.xp / player.xpNext, Palette.blue)
        love.graphics.setColor(Palette.ink)
        Font.print("LV " .. player.level, left + BAR_W + BAR_TEXT_GAP, top + 8)
    else
        love.graphics.setColor(Palette.ink)
        Font.print("LV " .. player.level, edge, vh - ins.b - 12)
        bar(edge, vh - ins.b - 6, BAR_W, 4, player.xp / player.xpNext, Palette.blue)
    end

    -- The stick is taken away while the run is held -- the whole page answers
    -- the pause card, corner included -- so it is not drawn either.
    if game.state ~= "paused" then drawStick() end
    drawSelector(game)

    -- Nothing to hold once the run is over; that corner goes back to the page.
    -- Nothing to hold mid-draft either -- a level has to be spent before the run
    -- will take an instruction, so the button would only be a thing that does
    -- nothing when pressed.
    if game.state ~= "dead" and game.state ~= "levelup" then drawPause(game) end

    -- One line at the bottom of the page for whatever just changed. The upgrade
    -- you took wins over the tool you switched to: it is the rarer event and it
    -- is the one you cannot see anywhere else on the screen.
    if game.noticeT > 0 then
        love.graphics.setColor(game.noticeT > 0.5 and Palette.red or Palette.slate)
        Font.printCentered(game.notice, centre, vh - ins.b - 14)
    elseif game.toolLabel > 0 then
        -- The run's tool rather than the catalogue's: game.tool is a slot on the
        -- strip now, and which tool is in it is something only the run knows.
        local tool = game.loadout:tool(game.tool)
        if tool then
            love.graphics.setColor(game.toolLabel > 0.25 and Palette.slate or Palette.graphite)
            Font.printCentered(tool.name, centre, vh - ins.b - 14)
        end
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
