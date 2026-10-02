-- Drawn in canvas space (no camera transform) so it stays crisp on the grid.
--
-- Every position here is measured off the safe area rather than the canvas
-- edge, so nothing ends up under a notch or a gesture bar on a phone.

local Palette = require("src.palette")
local Font = require("src.font")
local I18n = require("src.i18n")
local Sprites = require("src.sprites")
local Tools = require("src.tools")
local Upgrades = require("src.upgrades")
local Input = require("src.input")
local pixelart = require("src.pixelart")

local Hud = {}

-- Tool selector: a stack of boxes down one edge, one per tool this run has
-- unlocked. Four at the most, and one at the start -- the strip is drafted, not
-- issued (src/loadout.lua).
--
-- Which edge is not a constant, and the rule is ergonomic rather than
-- decorative: the thumb stick owns a bottom corner (`Input.stickSide`) and
-- everything you *press* belongs to the other thumb, since one hand walks and
-- the other draws. So the tools are always in the margin opposite the stick, and
-- the weapon column -- read rather than pressed, and only on a held screen where
-- there is no stick at all -- takes whichever margin the tools left. Both
-- margins are claimed at their full width the whole time either way, so nothing
-- laid out between them (the draft's cards) moves when the sides swap.
local SEL_SIZE, SEL_GAP = 13, 3
-- Exported for the other place a box with a tool-sized drawing in it is pressed:
-- the draft's three bought buttons (src/levelup.lua). Sharing the number is what
-- keeps them reading as the same kind of thing as the selector rather than as
-- oversized corner buttons.
local SEL_MARGIN = 4          -- from the right edge of the safe area
local SEL_POP = 3             -- how far the selected tool slides out
local COLUMN_GAP = 4          -- clearance a margin column keeps from the page
local PITCH = SEL_SIZE + SEL_GAP

-- The margin the tools are in, and the one the weapons are in. Opposite the
-- stick and opposite each other; one definition, since a column drawn on one
-- side and hit-tested on the other is a selector that cannot be pressed.
Hud.SEL_SIZE = SEL_SIZE

function Hud.toolSide()
    return Input.stickSide == "right" and "left" or "right"
end

local function weaponSide()
    return Input.stickSide == "right" and "right" or "left"
end

-- Where a column's boxes stand, against its own edge of the safe area.
local function columnX(game, side)
    if side == "left" then return game.inset.l + SEL_MARGIN end
    return game.vw - game.inset.r - SEL_MARGIN - SEL_SIZE
end

-- Which way is *into the page* from a column. One number does both of the things
-- a column does sideways -- the picked box slides this way and the level beside
-- it is written this way -- because both are the same statement: a margin column
-- faces the page, and everything it has to say it says towards it.
local function pageDir(side)
    return side == "left" and 1 or -1
end
-- A box to the level beside it. Both margin columns put a level next to a box
-- and both measure their width off this, which is what keeps them mirror images
-- of each other rather than two columns that happen to look similar.
local CARRY_LEVEL_GAP = 2

-- A column or row of boxes to the slot counter under it.
local COUNT_GAP = 3

local function levelText(level)
    return tostring(level)
end

-- The level written beside a box, on the page side of it: the two columns face
-- each other across the page rather than both reading left to right. `x` is the
-- box's own left edge, whichever margin it is standing in.
local function drawLevel(text, side, x, y)
    y = y + math.floor((SEL_SIZE - Font.height) / 2)
    if side == "left" then
        Font.print(text, x + SEL_SIZE + CARRY_LEVEL_GAP, y)
    else
        Font.printRight(text, x - CARRY_LEVEL_GAP, y)
    end
end

-- "2/4" for one kind of line, and whether that kind is full.
--
-- All three of the places a run's lines are shown get one, because until they
-- did, a card that stopped coming up read as luck rather than as a rule: the
-- draft quietly drops every line of a kind the run has no room to start
-- (`Loadout.SLOTS`), and nothing said so. It goes red on full, which is the
-- moment the rule starts applying and the only moment it needs reading.
local function slotText(game, kind)
    local used, cap = game.loadout:slots(kind)
    if not cap then return tostring(used), false end
    return used .. "/" .. cap, used >= cap
end

-- The two readout bars at the ends of the top row, health and ink. Same size,
-- because they are the same kind of thing read the same way.
--
-- Their height is not a number of its own: it is `CORNER_SIZE`, the pause button
-- standing between them, taken below where that is declared. A row whose middle
-- is eleven tall and whose two ends are six is three things that happen to share
-- an edge; struck off one height it is a row, and the button reads as the third
-- readout in it rather than as something dropped on top.
--
-- Sixty is what a bar is worth on a landscape page and the most one is ever
-- drawn at. It is not what one is always drawn at: a portrait phone is a hundred
-- and eighty game pixels across at the widest, and two sixty-pixel bars with
-- their numbers on the inside meet in the middle of that, on top of the clock.
--
-- So the row is measured rather than written down. The clock keeps the middle of
-- the page and a gap either side of itself; each bar gets what is left between
-- that and its own end of the row, and both are then cut to the shorter of the
-- two -- they are twins, and a health bar longer than the ink meter beside it is
-- a health bar that reads as fuller than it is.
--
-- The two ends are not the same length, which is why both are worked out rather
-- than one being halved: the clock is centred on the *page* while this row
-- starts clear of the pause button, so the health end is a corner button and a
-- gap shorter than the ink end. Splitting the row down its own middle instead
-- puts the health figure under the clock on a portrait page and nowhere near it
-- on a landscape one.
--
-- The floor is what the bar is still a *bar* at. Below about two dozen pixels a
-- fifth of a page of health is four pixels of red, which is a light rather than
-- a length, and at that point the row is better off letting the pair meet the
-- clock than pretending to still be readable.
local BAR_MAX_W, BAR_MIN_W = 60, 24
local BAR_TEXT_GAP = 4        -- bar to the number beside it
local BAR_CLOCK_GAP = 4       -- a bar's number to the clock in the middle

-- Both the clock and the two numbers are struck off the widest they ever get
-- rather than off what they happen to say, which is the rule the canteen keeps
-- room for its purse by: bars that grew a pixel as the clock ticked past ten
-- minutes, or as a hit took health from three digits to two, would be bars whose
-- length was answering two questions at once. Five characters of clock and three
-- of figure is every run this game will ever have.
local function barWidth(left, right, centre)
    local clockW = Font.width("00:00")
    -- Where the clock actually lands, floored the way Font.printCentered floors
    -- it, so the gap either side of it is the gap that gets drawn.
    local clockL = math.floor(centre - clockW / 2)
    local keep = BAR_CLOCK_GAP + BAR_TEXT_GAP + Font.width("000")

    local room = math.min(clockL - left - keep,
                          right - (clockL + clockW) - keep)
    return math.max(BAR_MIN_W, math.min(BAR_MAX_W, room))
end

-- Experience: one bar the width of the page along the very bottom of it, with
-- the level printed in the middle. Seven is the one measurement here that is not
-- free -- five rows of lettering with a pixel of border either side.
local XP_H = 7

-- The corner button: the top-left of the safe area, off the same 4px margin the
-- readouts use, with the health bar starting to the right of it. Both side
-- margins belong to the two columns, each claimed at its full width whether the
-- run has one tool in it or four; a bottom corner belongs to the thumb stick.
-- This is the one corner with room in it.
--
-- It is the one piece of furniture here that does *not* mirror with the stick.
-- Every screen in the game has this button in this corner -- the timetable's way
-- back, the library's, the settings page's -- and none of those has a stick to
-- be opposite; a button that moved on one screen out of six would be a button
-- you have to look for. It is also at the top, which is the far end of the page
-- from either thumb.
--
-- Two screens put something there and it is the same box both times: the run's
-- pause button, and the timetable's way back to the title (src/timetable.lua).
-- A screen you leave by pressing a corner should be left the way the last one
-- was, so the box, its touch allowance, its hit test and how it is drawn live
-- here once rather than being agreed on twice.
local CORNER_SIZE = 11
local CORNER_MARGIN = 4

local BAR_H = CORNER_SIZE

Hud.CORNER_SIZE = CORNER_SIZE
-- Exported for the mirror of it: the canteen hangs its purse readout off the
-- *right* end of this same top edge (src/canteen.lua), and the two only read as
-- level with each other while they are the same distance in from their own edge.
Hud.CORNER_MARGIN = CORNER_MARGIN

-- A finger is a lot bigger and a lot blinder than a mouse pointer, so the
-- touch target reaches further out from the boxes than the mouse one does.
local function selectorPad()
    if Input.usingTouch then return 11, 6 end
    return 4, 2
end

-- The same allowance for the corner button, which shares this edge.
local function cornerPad()
    return Input.usingTouch and 5 or 2
end

function Hud.cornerBox(game)
    return game.inset.l + CORNER_MARGIN, game.inset.t + CORNER_MARGIN
end

-- The first row of the page a screen with a corner button has left over. The
-- timetable measures its panel down from here rather than from the safe edge,
-- since a panel centred against the whole page walks up under the button on a
-- short screen and the button is the one thing on that screen you cannot draw on.
function Hud.cornerBottom(game)
    return game.inset.t + CORNER_MARGIN + CORNER_SIZE
end

-- The foot button: the same box, the same margin, the other end of the same left
-- edge. The title screen wants two ways off it and they are not the same kind of
-- thing -- one opens a screen and one throws a switch -- so they are put as far
-- apart as one margin goes rather than stacked, and being the same box at both
-- ends is what says they belong to the same edge of the same page.
--
-- It is only ever drawn on a screen with no thumb stick, because that corner
-- belongs to the stick while a run is going. That is not enforced here: nothing
-- during a run asks for it.
--
-- Where the corner button takes an icon, this takes a *word*. A language is two
-- letters and there is no drawing of a language, which is the same reason the
-- timetable's LIBRARY tab carries lettering while every other tab carries a tool.
function Hud.footBox(game)
    return game.inset.l + CORNER_MARGIN,
           game.vh - game.inset.b - CORNER_MARGIN - CORNER_SIZE
end

-- The first row of page above it, for a screen laying something out down to the
-- bottom edge -- the mirror of Hud.cornerBottom.
function Hud.footTop(game)
    return game.vh - game.inset.b - CORNER_MARGIN - CORNER_SIZE
end

-- The same thing for the *run's* bottom edge: the first row of page above the
-- experience bar. The bar spans the whole width now, so the bottom edge is no
-- longer a strip anything can share -- it is one readout, and a screen held over
-- a run (the draft, src/levelup.lua) stands its own furniture on top of this
-- rather than on the safe inset, the way everything sharing the top row starts
-- clear of the corner button. Asked for rather than guessed at, so the bar can be
-- made taller without a second screen having to be told.
function Hud.xpTop(game)
    return game.vh - game.inset.b - XP_H
end

local function selectorX(game)
    return columnX(game, Hud.toolSide())
end

-- Everything the tool column claims off its edge of the safe area: the boxes,
-- the pop of the selected one, and the level that appears beside them while the
-- run is held. A screen that wants to lay something out across the page (the
-- draft, src/levelup.lua) asks for this rather than guessing, because anything
-- under this column is something you can only see part of.
--
-- The room for the level is claimed all the time, though it is only drawn some
-- of the time, for the same reason the weapon margin is claimed while it is
-- empty: a margin that grows the moment a card is drawn on it is a margin that
-- moves the cards out from under the pointer about to circle one.
--
-- The two are different by exactly the pop, since only the tools have one, and
-- they follow their columns across the page rather than being nailed to an edge:
-- what a margin is worth is what stands in it.
local function toolMargin()
    return SEL_MARGIN + SEL_SIZE + SEL_POP
         + CARRY_LEVEL_GAP + Font.width("8") + COLUMN_GAP
end

local function weaponMargin()
    return SEL_MARGIN + SEL_SIZE + CARRY_LEVEL_GAP + Font.width("8") + COLUMN_GAP
end

function Hud.rightMargin()
    if Hud.toolSide() == "right" then return toolMargin() end
    return weaponMargin()
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

-- The foot of a column of boxes, which is where its counter hangs. Deliberately
-- *not* part of what columnTop centres: an empty column and a full one keep
-- their boxes in the same place, and pausing does not slide the selector you
-- were just pressing up the page to make room for a number.
local function columnBottom(game, count)
    return columnTop(game, count) + math.max(0, count * PITCH - SEL_GAP)
end

-- A column with more in it than the page has room for becomes a *window* onto
-- its list rather than a column running off both ends of the paper.
--
-- A drafted run can never ask for one: four slots of each kind (`Loadout.SLOTS`)
-- against room for seven boxes on the shortest page the game runs on. A *lent*
-- one can, and by miles -- the dev switches hand over every line of a kind at
-- once (Game:toggleDev), which is thirty-four tools, five hundred and forty
-- pixels of boxes down a page a hundred and eighty tall. Every one of them was
-- drawn, none of them could be read, and the ones off the bottom could not be
-- picked up at all.
--
-- The rule is written in terms of room rather than in terms of the switch, so
-- nothing here has to know why a column is long: a column that does not fit is a
-- column that does not fit. It shows as many boxes as fit, keeps one entry --
-- the picked tool, or where the reader has scrolled to -- inside the window, and
-- puts a mark on whichever end it cut. Short columns go through all of this
-- untouched and come out exactly where they were before it existed.
local MARK_DROP = 2           -- the end box to the mark past it
local MARK_H = 3              -- the mark itself, a 5-3-1 arrowhead

-- The furniture that stands at the ends of a margin, which a column at full
-- length is drawn straight over: the corner button at the top (fifteen rows down
-- from the safe edge), the experience bar along the whole of the bottom edge
-- (seven up, and it crosses both margins rather than standing in one), and --
-- the deepest of the three, so the one that decides this number -- the draft's
-- row of bought buttons with its own figure over each, off the same corner
-- (src/levelup.lua: seven off the edge, a box, a gap and a figure). All three
-- are drawn on the very screens these columns are read on.
local EDGE_KEEP = 27

-- What each end of a column has to keep clear: the mark that may appear there,
-- and the furniture past it. The same allowance at both ends rather than one each
-- -- the top end has less standing in it -- because the boxes are centred on the
-- midline: a column with more room below it than above would sit off the middle
-- of the page, and the two of them facing each other across it is the whole of
-- why they are struck off one line.
--
-- The slot counter is not in here, because a windowed column does not draw one.
local function columnSlack()
    return MARK_DROP + MARK_H + EDGE_KEEP
end

-- How many boxes a margin column has room for between the safe insets.
local function columnRoom(game)
    local h = game.vh - game.inset.t - game.inset.b - 2 * columnSlack()
    return math.max(1, math.floor((h + SEL_GAP) / PITCH))
end

-- The slice of a `count`-long list a column shows: the first index in it and how
-- many. `focus` is the entry that has to stay inside the window, and it is put
-- in the middle of it -- which is what makes a window scroll with no scroll
-- state at all in the tools' case, since moving the picked slot one step off the
-- middle slides the window one step after it. That is also the whole of how a
-- phone reaches the far end of a long strip: pressing the box above the picked
-- one is a press that scrolls.
local function columnWindow(game, count, focus)
    local shown = math.min(count, columnRoom(game))
    if shown >= count then return 1, count end

    local first = (focus or 1) - math.floor((shown - 1) / 2)
    return math.max(1, math.min(count - shown + 1, first)), shown
end

-- The cut end of a window, marked with a small arrowhead pointing off the page
-- the way the list goes on. Drawn in graphite rather than slate: it is not
-- another thing in the column, it is the column admitting it is not all here.
local function drawWindowMark(x, y, dir)
    love.graphics.setColor(Palette.graphite)
    for i = 0, MARK_H - 1 do
        local w = 5 - i * 2
        love.graphics.rectangle("fill",
            math.floor(x + (SEL_SIZE - w) / 2), y + i * dir, w, 1)
    end
end

-- Both ends of a window, given where its first box stands. Handed the whole
-- window rather than working it out again, since the caller has just drawn it.
local function drawWindowMarks(x, top, first, shown, count)
    if first > 1 then
        drawWindowMark(x, top - MARK_DROP - 1, -1)
    end
    if first + shown - 1 < count then
        drawWindowMark(x, top + shown * PITCH - SEL_GAP + MARK_DROP, 1)
    end
end

-- Centred under a column of boxes, on the box's own midline.
local function drawSlotCount(game, kind, boxX, y)
    local text, full = slotText(game, kind)
    love.graphics.setColor(full and Palette.red or Palette.slate)
    Font.printCentered(text, boxX + SEL_SIZE / 2, y)
end

-- How many boxes there are to draw and to press: what this run has unlocked, not
-- what the game has to offer. The column grows as a run drafts tools, so it is
-- measured every time rather than being a constant.
local function equippedCount(game)
    return game.loadout and #game.loadout.equipped or 0
end

-- The slice of the strip on the page, and where it starts. The picked slot is
-- what the window is kept around, so the tool in your hand is always one of the
-- boxes you can see -- and on a strip short enough to fit, which is every strip
-- a real run carries, this is the whole strip and the top it always had.
local function selectorWindow(game)
    return columnWindow(game, equippedCount(game), game.tool)
end

local function selectorTop(game, shown)
    return columnTop(game, shown or select(2, selectorWindow(game)))
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
    -- Everything from the column's inner edge out to the side of the page it is
    -- against: the margin is the column's alone, so a press anywhere in it is a
    -- press on the strip.
    local x = selectorX(game)
    if Hud.toolSide() == "left" then
        if cx > x + SEL_SIZE + SEL_POP + padX then return nil end
    elseif cx < x - SEL_POP - padX then
        return nil
    end

    -- Against the window rather than the strip: a press lands on the box it
    -- lands on, and which slot that box is showing is the window's business.
    local first, shown = selectorWindow(game)
    local top = selectorTop(game, shown)
    local total = shown * PITCH - SEL_GAP
    if cy < top - padY or cy > top + total + padY then return nil end

    local index = first + math.floor((cy - top) / PITCH)
    return math.max(first, math.min(first + shown - 1, index))
end

-- The corner button's press target: the box plus the allowance round it. Same
-- reasoning as the selector -- a finger needs more room than a mouse pointer
-- does -- and it is handed out whole so a screen that has to know what a press
-- there will claim (the timetable, which must not draw ink under it) asks for
-- the target rather than measuring one of its own.
function Hud.cornerTarget(game)
    local pad = cornerPad()
    local x, y = Hud.cornerBox(game)
    return x - pad, y - pad, CORNER_SIZE + pad * 2, CORNER_SIZE + pad * 2
end

-- Whether a canvas-space point presses the corner button.
function Hud.cornerAt(game, cx, cy)
    local x, y, w, h = Hud.cornerTarget(game)
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

function Hud.footTarget(game)
    local pad = cornerPad()
    local x, y = Hud.footBox(game)
    return x - pad, y - pad, CORNER_SIZE + pad * 2, CORNER_SIZE + pad * 2
end

function Hud.footAt(game, cx, cy)
    local x, y, w, h = Hud.footTarget(game)
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

--- pieces --------------------------------------------------------------------

local function drawStick()
    if not Input.usingTouch then return end

    local ox, oy, kx, ky, active, tilt = Input.stickState()

    -- The ring is a pencil circle on the page; the knob is a drawn blob that
    -- fills with the player's blush once you have hold of it.
    --
    -- Red is kept for one thing here, and it is not "held": it is full tilt.
    -- There is no speed above it, so a thumb pushing on for more is pushing for
    -- nothing, and the ring going red with the knob pinned against it is the
    -- only account the corner can give of that. Two signals, one each, rather
    -- than one colour meaning both.
    local full = tilt >= 1
    love.graphics.setColor(full and Palette.red or Palette.graphite)
    pixelart.circleOutline(ox, oy, Input.STICK_R)
    love.graphics.setColor(active and Palette.blush or Palette.paper)
    pixelart.circleFill(kx, ky, Input.KNOB_R)
    love.graphics.setColor(full and Palette.red or Palette.slate)
    pixelart.circleOutline(kx, ky, Input.KNOB_R)
end

-- The same box the tool selector draws, one size down: it belongs to the same
-- set of things you press. `hot` turns it red, which is what the pause button
-- does while the run is held so the frozen page has an obvious way out of it.
--
-- Filled in paper like every other box in the margins, so it is a thing lying on
-- the page rather than a window onto it -- which is also why any screen drawing
-- it has to draw it *after* the overprint pass, next to the rest of the HUD.
function Hud.drawCorner(game, icon, hot)
    local x, y = Hud.cornerBox(game)
    Hud.drawButton(x, y, CORNER_SIZE, icon, hot)
end

-- The same box at a position and a size the caller picks, for a screen with a row
-- of them rather than one in a corner: the draft's three bought buttons
-- (src/levelup.lua, src/perks.lua). It is the corner button's own recipe and not a
-- second one, because a thing you press should look the same wherever this game
-- puts it -- so the corner button is drawn *through* here rather than beside it.
--
-- `size` is the whole of the difference between the two: `CORNER_SIZE` holds one of
-- the small HUD glyphs and `SEL_SIZE` holds a tool-sized 11x11 drawing with a
-- border round it, which is why the tool selector is the bigger of the two and why
-- the buttons that carry the same size of drawing take the same box.
--
-- `dim` is a button with nothing left in it, drawn rather than dropped: one that
-- vanished when it was spent would move the two standing next to it, which is the
-- same rule the margin columns are claimed empty under. The icon goes down as its
-- own silhouette in the border's colour (`drawMask`, the sun's bleach trick),
-- since a red cross or a blue arrow inside a grey box would be a spent button
-- still shouting.
function Hud.drawButton(x, y, size, icon, hot, dim)
    local edge = dim and Palette.graphite
        or (hot and Palette.red or Palette.slate)

    love.graphics.setColor(edge)
    love.graphics.rectangle("fill", x, y, size, size)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2)

    Hud.drawIcon(icon, x + size / 2, y + size / 2, dim and edge or nil)
end

-- Every icon this game puts on a page goes down through here, and there is one
-- reason for that: a fused tool (`Upgrades.fused`) is drawn on a plate of blush
-- and everything else is drawn on nothing, so *where* that happens is a fact
-- about the game rather than a list of screens that remembered. The selector
-- column, the shelf in the library and the entry under it all draw the same
-- fusion the same way without any of them knowing what a fusion is.
--
-- Blush was already the fusion's colour before it was a plate: it is the fill of
-- the one card in the draft that offers one (src/levelup.lua), which is where a
-- player meets the idea. This is that card's colour following the tool out of the
-- draft and onto everything it turns up on afterwards -- and inside the selector
-- box it lands exactly, since the box is thirteen with a one-pixel border and
-- every icon in this game is eleven across.
--
-- The plate is measured off the drawing rather than off an eleven written down
-- here, the way the shadow under a hero is (`Sprites.shadow`), and it is floored
-- to the same pixel the drawing is: half a pixel out either way is a plate with
-- ink hanging off one edge of it.
--
-- `mask` is a colour to draw the silhouette in instead of the drawing -- a spent
-- button, a line the book has not opened -- and it takes no plate by default: a
-- thing drawn as the hole it is has nothing to be special about yet. `plate`
-- overrides both ways round for the one screen that has something else to say
-- with the colour: the library's pair of picks (src/library.lua), where blush on
-- a tool means it is going *into* a fusion rather than being one.
function Hud.drawIcon(icon, cx, cy, mask, plate)
    local sprite = Sprites.icons[icon]

    if plate == nil then plate = Upgrades.fused[icon] and not mask end
    if plate then
        love.graphics.setColor(Palette.blush)
        love.graphics.rectangle("fill",
            math.floor(cx) - sprite.ox, math.floor(cy) - sprite.oy,
            sprite.w, sprite.h)
    end

    if mask then
        love.graphics.setColor(mask)
        sprite:drawMask(cx, cy)
    else
        love.graphics.setColor(1, 1, 1)
        sprite:draw(cx, cy)
    end
end

-- The corner button's twin at the foot of the same margin, with a word in it
-- instead of an icon. Same border, same paper fill, same reason for both: it is a
-- thing lying on the page rather than a window onto it, so a screen drawing it
-- draws it after the overprint pass with the rest of the HUD.
--
-- Two letters is what it is cut for -- eleven pixels holds seven of lettering
-- with two either side -- and anything longer is centred and allowed to run over
-- the border rather than being shrunk, since there is nothing smaller than this
-- face to shrink to.
function Hud.drawFoot(game, text, hot)
    local x, y = Hud.footBox(game)

    love.graphics.setColor(hot and Palette.red or Palette.slate)
    love.graphics.rectangle("fill", x, y, CORNER_SIZE, CORNER_SIZE)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, CORNER_SIZE - 2, CORNER_SIZE - 2)

    love.graphics.setColor(hot and Palette.red or Palette.slate)
    Font.printCentered(text, x + CORNER_SIZE / 2,
        y + math.floor((CORNER_SIZE - Font.height) / 2))
end

local function drawPause(game)
    local paused = game.state == "paused"
    Hud.drawCorner(game, paused and "play" or "pause", paused)
end

local function drawSelector(game)
    local loadout = game.loadout
    if not loadout then return end

    local side = Hud.toolSide()
    local baseX = selectorX(game)
    local pop = pageDir(side) * SEL_POP

    -- What level each tool has reached, but only while the run is held -- the
    -- same rule the weapon column opposite follows, and for the same reason:
    -- mid-run the page is the thing you are reading, and a number in the margin
    -- is a number in the way. The moment the run stops is the moment you want to
    -- know, and it is also the only moment the two columns are read as a pair.
    local held = game.state == "paused" or game.state == "levelup"

    local count = #loadout.equipped
    local first, shown = selectorWindow(game)
    local top = selectorTop(game, shown)

    for i = first, first + shown - 1 do
        local slot = loadout.equipped[i]
        local selected = i == game.tool
        local x = baseX + (selected and pop or 0)
        local y = top + (i - first) * PITCH

        love.graphics.setColor(selected and Palette.red or Palette.slate)
        love.graphics.rectangle("fill", x, y, SEL_SIZE, SEL_SIZE)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, y + 1, SEL_SIZE - 2, SEL_SIZE - 2)

        Hud.drawIcon(slot.tool.icon, x + SEL_SIZE / 2, y + SEL_SIZE / 2)

        if held then
            love.graphics.setColor(Palette.slate)
            drawLevel(levelText(slot.level), side, x, y)
        end
    end

    -- On the boxes' own line rather than the popped one's, so the marks stay put
    -- as the pick slides in and out.
    drawWindowMarks(baseX, top, first, shown, count)

    -- No counter under a window, and the mark is why: the two would be the same
    -- three pixels of page. It is no loss -- a column only ever becomes a window
    -- when a dev switch has lent it every line of its kind, which is exactly the
    -- case where the four-slot rule the counter is there to teach is suspended,
    -- and the switch's own readout on the pause card already says so.
    if held and shown >= count then
        drawSlotCount(game, "tool", baseX, columnBottom(game, shown) + COUNT_GAP)
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

-- What is claimed off the left of the safe area, whether there is anything in it
-- yet or not -- the mirror of Hud.rightMargin, and kept as fixed as that one is.
--
-- It would be free to hand the width back while the column is empty, and it is
-- deliberately not: the cards would then be wider on the drafts before your
-- first weapon than on the ones after it, and the layout would rearrange itself
-- underneath the thing you were about to circle on the one draft you were
-- guaranteed to be looking at it. A margin that is only sometimes there is worse
-- than a margin.
function Hud.leftMargin()
    if Hud.toolSide() == "left" then return toolMargin() end
    return weaponMargin()
end

-- The height the line of passives needs, so a screen can leave room for it in
-- its stack before it lays anything out: a level, the box under it, and the slot
-- counter under that.
--
-- Never nothing, because the counter is drawn whether the row has anything in it
-- or not -- "0/5" on the first draft of a run is the one that teaches the rule,
-- and a row that only appears once you already own a passive would teach it to
-- exactly the people who no longer need telling.
function Hud.passiveRow(game)
    if carriedCount(game, "passive") == 0 then return Font.height end
    return Font.height + CARRY_NUM_GAP + SEL_SIZE + COUNT_GAP + Font.height
end

local function passiveWidth(game)
    local n = carriedCount(game, "passive")
    if n == 0 then return 0 end
    return n * SEL_SIZE + (n - 1) * CARRY_GAP
end

-- The weapon column's window, and the one place a window needs a scroll of its
-- own: nothing in this column is picked, so there is no pick for it to follow.
-- `game.carryScroll` is simply which entry stands at the top of it, stepped a
-- page at a time (Game:scrollCarry) and clamped here rather than there, so a
-- column that got shorter -- the switch handed back, the window taller after a
-- resize -- comes back on screen by itself instead of staying scrolled off the
-- end of a list that no longer goes that far.
--
-- Handed out because the press that steps it has to know whether there is
-- anything to step (Game:pointerDown).
function Hud.weaponWindow(game)
    local count = carriedCount(game, "weapon")
    local shown = math.min(count, columnRoom(game))
    local first = 1 + math.max(0, math.min(count - shown, game.carryScroll or 0))
    return first, shown, count
end

-- Whether a canvas-space point is in the weapon margin, which is worth asking
-- only while that column is a window: everywhere else the margin is a thing to
-- read and a press there is ink like any other.
function Hud.weaponAt(game, cx, cy)
    local _, shown, count = Hud.weaponWindow(game)
    if shown >= count then return false end

    local side = weaponSide()
    local x = columnX(game, side)
    local padX = selectorPad()
    if side == "left" then return cx <= x + SEL_SIZE + padX end
    return cx >= x - padX
end

function Hud.drawWeapons(game)
    local first, shown, count = Hud.weaponWindow(game)
    local top = columnTop(game, shown)
    local side = weaponSide()
    local x = columnX(game, side)
    local i = 0

    eachCarried(game, "weapon", function(up, level)
        i = i + 1
        if i < first or i >= first + shown then return end
        local y = top + (i - first) * PITCH

        -- The tool selector's box exactly, minus the pop and the red: nothing
        -- here is selected, because none of it is something you pick up.
        love.graphics.setColor(Palette.slate)
        love.graphics.rectangle("fill", x, y, SEL_SIZE, SEL_SIZE)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, y + 1, SEL_SIZE - 2, SEL_SIZE - 2)

        Hud.drawIcon(up.icon, x + SEL_SIZE / 2, y + SEL_SIZE / 2)

        love.graphics.setColor(Palette.slate)
        drawLevel(levelText(level), side, x, y)
    end)

    drawWindowMarks(x, top, first, shown, count)

    -- Under the column even when the column is empty, which is the one case it
    -- is doing the most work: a run that has never been offered a weapon still
    -- gets told there are four places to put one. Not under a window, though --
    -- see the same rule under the selector column.
    if shown >= count then
        drawSlotCount(game, "weapon", x, columnBottom(game, shown) + COUNT_GAP)
    end
end

-- Centred on cx, with the levels' tops at y, the boxes under them and the slot
-- counter under those. An empty row is the counter alone, sitting where the row
-- would have been -- which is why this measures its own height rather than being
-- handed one, and why Hud.passiveRow has to agree with it.
function Hud.drawPassives(game, cx, y)
    local total = passiveWidth(game)
    local countY = y

    if total > 0 then
        local x = math.floor(cx - total / 2)
        local boxY = y + Font.height + CARRY_NUM_GAP
        countY = boxY + SEL_SIZE + COUNT_GAP

        eachCarried(game, "passive", function(up, level)
            local text = levelText(level)
            love.graphics.setColor(Palette.slate)
            Font.print(text, x + math.floor((SEL_SIZE - Font.width(text)) / 2), y)

            love.graphics.setColor(Palette.slate)
            love.graphics.rectangle("fill", x, boxY, SEL_SIZE, SEL_SIZE)
            love.graphics.setColor(Palette.paper)
            love.graphics.rectangle("fill", x + 1, boxY + 1, SEL_SIZE - 2, SEL_SIZE - 2)

            Hud.drawIcon(up.icon, x + SEL_SIZE / 2, boxY + SEL_SIZE / 2)

            x = x + SEL_SIZE + CARRY_GAP
        end)
    end

    -- On the row's own centre line rather than a box's, since the row is centred
    -- on the page and the columns are not.
    local text, full = slotText(game, "passive")
    love.graphics.setColor(full and Palette.red or Palette.slate)
    Font.printCentered(text, cx, countY)
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

-- The boss's health, hung under the run timer for as long as there is a boss.
-- Top centre because that is the one place on the page nothing else claims, and
-- because it is where the clock is: the clock is what said the fight was coming,
-- and the bar is what replaces it as the thing you are counting down.
--
-- Wider than the corner bars and a pixel shorter, so it reads as a different
-- kind of readout rather than a third copy of yours -- and in red, since it is
-- the same thing the health bar is: how much of a fight is left.
local BOSS_BAR_W, BOSS_BAR_H = 88, 5

local function drawBoss(game)
    local boss = game.boss
    if not boss then return end

    local ins = game.inset
    local centre = ins.l + (game.vw - ins.l - ins.r) / 2
    local x = math.floor(centre - BOSS_BAR_W / 2)
    -- Under the top row rather than under the clock: the clock sits inside that
    -- row now, so the first free line is past the bars either side of it.
    local y = ins.t + 4 + BAR_H + 3

    bar(x, y, BOSS_BAR_W, BOSS_BAR_H, boss.hp / boss.maxHp, Palette.red)

    love.graphics.setColor(Palette.ink)
    Font.printCentered(I18n.t("THE EYE"), centre, y + BOSS_BAR_H + 2)
end

function Hud.draw(game)
    local vw, vh = game.vw, game.vh
    local ins = game.inset
    local player = game.player
    local top = ins.t + 4
    local centre = ins.l + (vw - ins.l - ins.r) / 2

    -- Where the top row starts: the corner itself belongs to the pause button,
    -- so everything sharing that row begins clear of it. Six, not four: the
    -- button's touch target reaches five pixels past its own box, and a health
    -- bar with the button's grab zone lying across its left end is a bar that
    -- pauses the run when you press it.
    local left = ins.l + 4 + CORNER_SIZE + 6
    local right = vw - ins.r - 4

    -- What you have and what you can spend, in the two top corners: the same
    -- bar at the same size, each hung off its own edge of the page with its
    -- number on the inside. The ink meter used to be a thin gauge stood on end
    -- beside the tool column, which is where you look to *change* tool and not
    -- where you look mid-stroke; as the health bar's mirror image it is read
    -- the way the health bar is read, at a glance, from the length of it.
    --
    -- One midline for everything in the top row: the two numbers and the clock
    -- are all struck off the height of the bars, so raising or lowering the bars
    -- takes the lettering with it rather than leaving it stranded.
    local rowText = top + math.floor((BAR_H - Font.height) / 2)
    local barW = barWidth(left, right, centre)

    bar(left, top, barW, BAR_H, player.hp / player.maxHp, Palette.red)
    love.graphics.setColor(Palette.ink)
    Font.print(("%d"):format(player.hp), left + barW + BAR_TEXT_GAP, rowText)

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
    --
    -- Slate rather than blue, though the pen it pays for is blue: blue on this
    -- page means *the player's side of the fight*, and it is spent on the marks
    -- themselves everywhere you look -- the nib, the shots, the beam. A meter in
    -- the same blue is the readout claiming to be one of them. Grey is what the
    -- readout is: furniture, read for its length and not for its colour, which
    -- also leaves the blush at the bottom of it the only colour the meter ever
    -- takes and so the only thing about it that can shout.
    local inkX = right - barW
    bar(inkX, top, barW, BAR_H, game.ink / game.loadout.stats.inkMax,
        game.ink < Tools.MIN_INK and Palette.blush or Palette.slate, true)
    love.graphics.setColor(Palette.ink)
    Font.printRight(("%d"):format(game.ink * 100), inkX - BAR_TEXT_GAP, rowText)

    -- Run timer, top centre, with the boss's health under it while there is a
    -- boss.
    Font.printCentered(clock(game.time), centre, rowText)
    drawBoss(game)

    -- Level and experience, along the whole foot of the page, with the level
    -- printed in the middle of the bar it is filling.
    --
    -- It used to be a short bar in the bottom-left corner on desktop and tucked
    -- under the health bar on a phone -- two layouts for one readout, and neither
    -- of them anywhere you are looking. The bottom edge is the one strip of the
    -- page nothing else wants (the corners belong to the thumb stick and to
    -- nobody), and a bar that spans it is read without being looked at: the
    -- whole width of the screen is one level, and how far along it you are is
    -- the only thing you ever needed off this readout. So it is the same bar in
    -- the same place on both, and there is no branch left to get wrong.
    --
    -- The one thing on the page measured off the canvas rather than off the safe
    -- area, and it is the exception that proves the rule. The safe area is there
    -- so that nothing you have to *read* ends up under a notch, and a bar has
    -- nothing in it to read: it is a length, and a length that stops short of the
    -- corners is a length with two gaps at the ends that mean nothing. Run edge
    -- to edge it is the screen itself filling up. What is read off it -- the
    -- level -- is lettering in the middle of the page, which is the furthest
    -- point on this edge from either inset. It still stands *on* the bottom
    -- inset rather than under it, so a gesture bar cuts across nothing.
    --
    -- The level took the kill count's spot, and the swap is the point: kills is
    -- a number you read afterwards on the game over card, where it is half the
    -- score and is read next to the clock. The level is the one you are playing
    -- towards while the run is going, and the bar behind it is how close.
    local xpY = vh - ins.b - XP_H
    bar(0, xpY, vw, XP_H, player.xp / player.xpNext, Palette.blue)
    love.graphics.setColor(Palette.ink)
    Font.printCentered(I18n.t("LV %d"):format(player.level), centre, xpY + 1)

    -- The stick is taken away whenever the run is held -- the whole page answers
    -- the card that is holding it, corner included -- so it is not drawn either.
    -- Read off the stick itself rather than off a list of the states that hold
    -- the run (Game:holdRun), which is one place for a new one to be forgotten.
    if Input.stickEnabled then drawStick() end
    drawSelector(game)

    -- Nothing to hold once the run is over; that corner goes back to the page.
    -- Nothing to hold while a card is up either -- a level has to be spent, and
    -- a win has to be answered, before the run will take an instruction, so the
    -- button would only be a thing that does nothing when pressed.
    if game.state == "playing" or game.state == "paused" then drawPause(game) end

    -- One line at the bottom of the page for whatever just changed. The upgrade
    -- you took wins over the tool you switched to: it is the rarer event and it
    -- is the one you cannot see anywhere else on the screen.
    if game.noticeT > 0 then
        love.graphics.setColor(game.noticeT > 0.5 and Palette.red or Palette.slate)
        Font.printCentered(I18n.t(game.notice), centre, vh - ins.b - 14)
    elseif game.toolLabel > 0 then
        -- The run's tool rather than the catalogue's: game.tool is a slot on the
        -- strip now, and which tool is in it is something only the run knows.
        local tool = game.loadout:tool(game.tool)
        if tool then
            love.graphics.setColor(game.toolLabel > 0.25 and Palette.slate or Palette.graphite)
            Font.printCentered(I18n.t(tool.name), centre, vh - ins.b - 14)
        end
    end
end

return Hud
