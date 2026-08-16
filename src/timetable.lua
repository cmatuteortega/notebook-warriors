-- The timetable: which page of the book this run is played on.
--
-- It sits between the title screen and the board your character is drawn on,
-- which is the only place it can sit. The subject decides how the page is ruled
-- and the ruling is what the drawing is read against (src/overprint.lua), so
-- picking it after the hero is drawn would mean drawing him against one page and
-- playing him on another.
--
-- It is a register: one stripe per subject down the page, the tool that lesson
-- hands you at each end of it, and the box you answer in out to the right. The
-- heading sits over that column of boxes rather than over the middle of the
-- screen, because the right-hand edge is the one every row lines up on and a
-- title is a thing you read before the list under it.
--
-- Nothing on a stripe is a picture of the page. It used to be -- this screen was
-- a grid of cards and every one carried a swatch of its own ruling -- and the reason it does not any more is
-- that **the page underneath is the answer, live**: whichever box is armed is
-- the paper the whole screen is standing on, so the ruling under the question is
-- already the ruling you are about to play on, at full size and across the whole
-- screen rather than in a 20px window. A swatch was a smaller second copy of
-- something the screen was showing anyway. What the stripe shows instead is the
-- half of a lesson the page cannot show: the tool it puts in your hand.
--
-- So the stripes are drawn *on* the page rather than on paper laid over it,
-- along with the heading and the hint. There is nothing here that has to hide
-- what is behind it -- which is the whole difference between this screen and the
-- draft, where a card is opaque because a frozen run is too busy to read
-- lettering against.
--
-- A box is answered the way everything in this game is answered
-- (src/scribble.lua): scribble in it, or tap the stripe and the scribble is
-- drawn for you.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Sprites = require("src.sprites")
local Subjects = require("src.subjects")
local Upgrades = require("src.upgrades")
local util = require("src.util")

local Timetable = {}

local HEAD = "TODAYS LESSON"
local HEAD_SCALE = 2

local PAD = 4          -- stripe border to what is inside it
local ICON = 11        -- the tool's icon, and every icon in the game is 11x11
local ICON_GAP = 4     -- icon to the subject's name
local TOOL_GAP = 6     -- name to the tool it hands you, at the far end
local BOX_GAP = 6      -- stripe to the box out to its right
local ROW_GAP = 4      -- one stripe to the next
local EDGE = 4         -- and off the edge of the page
local HEAD_GAP, HINT_GAP = 6, 7

-- A stripe is as tall as there is room for, between an icon with a pixel to
-- spare above and below it and about twice that. The box out to the right is
-- given the same height, because a row and its answer are one thing and a box
-- half the height of the row it belongs to reads as belonging to neither it nor
-- the next one.
local ROW_MIN, ROW_MAX = 13, 22

-- A stripe stops widening here. It is a line of a register, not a banner: the
-- lettering inside one comes to about 87 pixels, so this leaves a bit over 60
-- between the lesson and the tool -- enough that they read as two ends of a row
-- rather than as one label, and not so much that they read as two things that
-- happen to share a rectangle. On the pages this game is usually handed it means
-- every stripe is the same 150 whatever the screen is doing, and the page shows
-- down both sides of the list, which is where the ruling you are picking is.
local STRIPE_MAX = 150

local STRIPE_TIME = 0.22 -- the stripes drawing themselves on as the screen opens
local CONFIRM = 0.34   -- the picked stripe flashing before the page turns

function Timetable:enter(key)
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.current = key or Subjects.default.key
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer still down from the title screen's YES is not this screen's to
    -- read: it draws nothing and taps nothing until it has been lifted.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()

    -- One unlabelled box per stripe -- the stripe beside it is the label.
    local defs = {}
    for i, sub in ipairs(Subjects.list) do
        defs[i] = { key = sub.key }
    end
    self.choice = Scribble.newChoice(defs, 1)

    self.stripes = {}
    for i = 1, #Subjects.list do
        self.stripes[i] = { box = self.choice.boxes[i] }
    end

    -- Nothing to walk here, and the corner the stick lives in is page like any
    -- other: you have to be able to scribble anywhere.
    Input.stickEnabled = false
end

--- layout --------------------------------------------------------------------

-- Every stripe is the same width and its parts line up down the screen: the
-- icon at the left edge, the subject flush after it, and the tool it hands you
-- flush against the right. Two columns of lettering with a gap of nothing much
-- in the middle is what makes a list read as a register rather than as seven
-- unrelated labels.
local function widths()
    local nameW, toolW = 0, 0
    for _, sub in ipairs(Subjects.list) do
        nameW = math.max(nameW, Font.width(sub.name))
        toolW = math.max(toolW, Font.width(Upgrades.byId[sub.tool].name))
    end
    return nameW, toolW
end

-- One stripe per subject, always, with no second column to fall back on: a
-- stripe is a whole row of the screen, so the only thing that has to give as
-- subjects are added is how tall each one is. Seven of them fit the shortest
-- page the game is ever handed with room over, which is the thing this shape
-- buys over the grid of cards it replaced -- that ran out of page at seven.
function Timetable:layout(game)
    local ins = game.inset
    local availW = game.vw - ins.l - ins.r
    local availH = game.vh - ins.t - ins.b
    local usable = availW - EDGE * 2

    local lay = {}
    local n = #self.stripes

    local nameW, toolW = widths()
    lay.nameX = PAD + ICON + ICON_GAP

    -- The tool's name is the first thing to go when the page is too narrow for
    -- it, and the icon is the last: an 11x11 glyph says which tool it is in a
    -- tenth of the width the word does, and this screen is one you learn rather
    -- than read.
    local bare = lay.nameX + nameW + PAD
    local full = bare + TOOL_GAP + toolW
    local room = usable - BOX_GAP - Scribble.BOX_W

    lay.tool = room >= full
    lay.stripeW = math.max(math.min(room, STRIPE_MAX), lay.tool and full or bare)

    local headH = Font.height * HEAD_SCALE

    -- The second hint line is the keyboard's, and it is the other thing that
    -- goes before the rows are squeezed: it names a shortcut for something you
    -- can already do by tapping the row it is talking about.
    local function hintFor(lines) return Font.height * lines + (lines - 1) * 2 end
    local function fixedFor(lines)
        return headH + HEAD_GAP + HINT_GAP + hintFor(lines) + ROW_GAP * (n - 1)
    end

    lay.hintLines = Input.usingTouch and 1 or 2
    if fixedFor(lay.hintLines) + n * ROW_MIN > availH then lay.hintLines = 1 end

    local fixed = fixedFor(lay.hintLines)
    lay.rowH = util.clamp(math.floor((availH - fixed) / n), ROW_MIN, ROW_MAX)

    local gridH = n * lay.rowH + ROW_GAP * (n - 1)

    local y = 0
    lay.head = y;  y = y + headH + HEAD_GAP
    lay.rows = y;  y = y + gridH + HINT_GAP
    lay.hint = y;  y = y + hintFor(lay.hintLines)

    local top = math.max(ins.t, math.floor(ins.t + (availH - y) / 2))
    lay.head = lay.head + top
    lay.rows = lay.rows + top
    lay.hint = lay.hint + top

    -- The stripes and their boxes are one block, centred; the heading is hung
    -- off its right edge and the hint centred under it, so the three agree about
    -- where the screen is even when the page is much wider than they are.
    local blockW = lay.stripeW + BOX_GAP + Scribble.BOX_W
    lay.cx = math.floor(ins.l + availW / 2)
    lay.left = math.floor(lay.cx - blockW / 2)
    lay.right = lay.left + blockW

    for i, stripe in ipairs(self.stripes) do
        stripe.x = lay.left
        stripe.y = lay.rows + (i - 1) * (lay.rowH + ROW_GAP)
        stripe.w, stripe.h = lay.stripeW, lay.rowH

        -- The box is the row's own height rather than the 20 every other box in
        -- the game is. Coverage is counted on a grid inside it (src/scribble.lua)
        -- and reads its size off the box, so a shorter one is answered by a
        -- shorter scribble and nothing else has to know.
        stripe.box.h = lay.rowH
        self.choice:place(stripe.box, stripe.x + stripe.w + BOX_GAP, stripe.y)
    end

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

function Timetable:commit(box)
    self.phase = "confirm"
    self.chosen = box
    self.confirmT = 0
end

-- Ink that lands in a box is the answer and is counted there; ink that misses is
-- just ink on the page, and fades off it.
function Timetable:mark(x, y, quiet)
    if self.choice:mark(x, y, quiet) then return end
    self.marks:add(x, y)
end

-- A press that lands on a stripe draws the scribble into the box out to its
-- right rather than jumping past it, exactly as the keyboard does. The stripe is
-- the target because it is the part that says what you are picking; the box is
-- there to be drawn in.
function Timetable:tap(x, y)
    for _, stripe in ipairs(self.stripes) do
        if x >= stripe.x and x < stripe.x + stripe.w
            and y >= stripe.y and y < stripe.y + stripe.h then
            self.choice:autoFill(stripe.box)
            return
        end
    end
end

-- The page the whole screen is standing on: the one being answered while a box
-- is armed or picked, and the one the book was last open at until then.
function Timetable:pageKey()
    local box = self.chosen or self.choice.armed
    return box and box.key or self.current
end

-- Returns the key of the subject that was picked, on the frame the pick takes
-- hold, and nothing at all until then.
function Timetable:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then return self.chosen.key end
        return
    end

    -- The keyboard and a tap both draw the scribble rather than jumping past it,
    -- and there is no pen to lift, so that answer stands as soon as the box
    -- fills.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end,
        function(px, py) self:tap(px, py) end)

    -- Armed, not answered: nothing is picked until the pen comes off the page,
    -- so a line that carries on into the next box changes its mind.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
    end
end

function Timetable:keypressed(key)
    if self.phase ~= "asking" then return end

    local slot = tonumber(key)
    if slot and self.stripes[slot] then
        self.choice:autoFill(self.stripes[slot].box)
    end
end

--- draw ----------------------------------------------------------------------

function Timetable:prompt()
    if self.choice.armed then
        return Input.usingTouch and "LIFT TO CONFIRM" or "RELEASE TO CONFIRM"
    end
    return "TAP A LESSON OR SCRIBBLE ITS BOX"
end

-- Counted off the stripes rather than written out, so a subject added to the book
-- is offered a key without this line having to be remembered. It stops at nine
-- because `keypressed` reads a single digit, so a tenth subject would be
-- scribbled for rather than pressed -- which is the route the screen is built
-- around anyway.
function Timetable:keyHint()
    local keys = {}
    for i = 1, math.min(#self.stripes, 9) do keys[i] = tostring(i) end
    return "OR PRESS " .. table.concat(keys, " ")
end

-- One line of the register: the tool's icon, the lesson, the tool's name out at
-- the far end, and the box it is answered in beyond that. The stripe and its box
-- warm and flash as one thing, both taking their colour from the box, because
-- they are one answer drawn in two pieces.
function Timetable:drawStripe(i, stripe)
    local sub = Subjects.list[i]
    local up = Upgrades.byId[sub.tool]
    local progress = util.clamp(self.t / STRIPE_TIME, 0, 1)
    local color = Scribble.boxColor(stripe.box, self.chosen, self.confirmT)

    Scribble.drawBox(stripe, progress, color, 20 + i * 3, 0)

    -- Centred on the row's midline rather than sat on its top edge, since the
    -- row's height is whatever the screen could spare and the icon's is not.
    local midY = stripe.y + math.floor(stripe.h / 2)
    Sprites.icons[up.icon]:draw(stripe.x + PAD + ICON / 2, midY)

    local textY = midY - math.floor(Font.height / 2)

    love.graphics.setColor(Palette.ink)
    Font.print(sub.name, stripe.x + self.lay.nameX, textY)
    if self.lay.tool then
        love.graphics.setColor(Palette.slate)
        Font.printRight(up.name, stripe.x + stripe.w - PAD, textY)
    end

    Scribble.drawBox(stripe.box, progress, color, 40 + i * 3, 0)
    Scribble.drawMarks(stripe.box.marks, Palette.ink, self.seed, 0)
end

function Timetable:draw(game)
    local lay = self:layout(game)

    -- The whole screen is written on the page rather than laid over it, stripes
    -- included, so the ruling shows through the question the same way it shows
    -- through a pencil line drawn mid-run -- and the ruling it shows through is
    -- the one being answered. There is nothing on this screen that has to cover
    -- what is behind it, which is why nothing here is drawn after the pass.
    Overprint.beginPage()
    Background.drawAs(self:pageKey(), 0, 0, game.vw, game.vh)

    Overprint.beginInk()
    self.marks:draw(0)

    -- Hung off the right-hand edge of the block, which is the edge the boxes
    -- line up on.
    Scribble.printBig(HEAD, lay.right - Font.width(HEAD) * HEAD_SCALE / 2,
        lay.head, HEAD_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    for i, stripe in ipairs(self.stripes) do
        self:drawStripe(i, stripe)
    end

    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(self:prompt(), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 61 })
        if lay.hintLines > 1 and not armed then
            Scribble.printBig(self:keyHint(), lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 62 })
        end
    end

    Overprint.finish()
end

return Timetable
