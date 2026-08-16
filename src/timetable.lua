-- The timetable: which page of the book this run is played on.
--
-- It sits between the title screen and the board your character is drawn on,
-- which is the only place it can sit. The subject decides how the page is ruled
-- and the ruling is what the drawing is read against (src/overprint.lua), so
-- picking it after the hero is drawn would mean drawing him against one page and
-- playing him on another.
--
-- One card per subject, however many there are, and each card is a piece of the
-- page it offers -- read straight off the tile that page is baked into
-- (src/background.lua), so what is on the card is exactly what the run will be
-- played on rather than an illustration of it. Under each is a box, and it is
-- answered the way everything in this game is answered (src/scribble.lua):
-- scribble in it, or tap the card and the scribble is drawn for you.
--
-- The page underneath is the answer, live. Whichever card is armed is the paper
-- the whole screen is standing on -- so the moment a box fills, the ruling under
-- the question changes to the one you are about to be playing on, and letting go
-- of the wrong box is a thing you can see before you do it.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Subjects = require("src.subjects")
local util = require("src.util")

local Timetable = {}

local HEAD = "TODAYS LESSON"
local HEAD_SCALE = 2

local PAD = 4          -- card border to what is inside it

-- The piece of the page itself, and the one measurement on this screen that is
-- not written down: it is whatever height the rest of the layout has not claimed,
-- between these two.
--
-- It has to be deep enough to show the *rhythm* of a ruling rather than a couple
-- of lines out of one, and how deep that is depends on the ruling. A page that
-- repeats on 10 says everything about itself in 16 rows; the paired ruling
-- repeats on 30, and in a 16-row window it is two lines 10 apart -- which is
-- exactly what plain ruled paper is, so at that depth two of the subjects hand
-- you the same card. 22 rows is where they come apart, and the floor is what the
-- screen falls back to when the cards will not fit any other way.
local SWATCH_MIN, SWATCH_MAX = 16, 26

local NAME_GAP = 3     -- swatch to the subject's name
local SAYS_GAP = 2     -- name to what its class is like
local GAP = 8          -- between one card and the next along a row
local ROW_GAP = 6      -- and between one row and the one under it, which needs
                       -- less: what sits above the gap is the box, and a box is
                       -- narrower than the card it belongs to, so the same 8
                       -- reads as more space than it does side to side. The two
                       -- pixels it gives back are what let the swatch reach the
                       -- 22 rows the paired ruling needs to be told from the
                       -- plain one on a 16:9 page.
local EDGE = 4         -- and off the edge of the page
local BOX_GAP = 4      -- card to the box under it
local HEAD_GAP, HINT_GAP = 6, 7

local CARD_TIME = 0.22 -- the cards drawing themselves on as the screen opens
local CONFIRM = 0.34   -- the picked card flashing before the page turns

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

    -- One unlabelled box per card -- the card above it is the label.
    local defs = {}
    for i, sub in ipairs(Subjects.list) do
        defs[i] = { key = sub.key }
    end
    self.choice = Scribble.newChoice(defs, 1)

    self.cards = {}
    for i = 1, #Subjects.list do
        self.cards[i] = { box = self.choice.boxes[i] }
    end

    -- Nothing to walk here, and the corner the stick lives in is page like any
    -- other: you have to be able to scribble anywhere.
    Input.stickEnabled = false
end

--- layout --------------------------------------------------------------------

-- Every card is the width of the widest thing any of them has to say, so they
-- read as one timetable rather than as notes of different sizes.
--
-- That puts a ceiling on the lettering, and it is worth knowing before writing a
-- new subject's `says`. The tightest page the game is ever handed is a 4:3
-- window: 240 canvas pixels across and only 180 down, which is too short for a
-- third row -- so on that page four cards have to fit across, or seven subjects
-- need three rows and no longer fit down it. Four cards and their gaps inside 232
-- usable pixels means a card of 52, which is **eleven characters**. A twelfth
-- costs that screen a row. (Narrower pages than 240 exist, but they are portrait
-- ones, and portrait has the height to spend on rows instead.)
local function cardWidth()
    local w = 0
    for _, sub in ipairs(Subjects.list) do
        w = math.max(w, Font.width(sub.name), Font.width(sub.says))
    end
    return w + PAD * 2
end

-- As many across as the page is wide enough for, and another row when they run
-- out -- which is how a timetable is laid out anyway, and it is what lets a
-- subject be added to the book without anything here being retuned. Never a
-- single column: a column of cards is taller than any screen this game runs on
-- as soon as there are three of them.
--
-- The rows are then evened out rather than left ragged: seven cards on a screen
-- four wide go 4 and 3 rather than 4, 2 and 1, and a short row is centred under
-- the full one instead of hanging off its left end.
function Timetable:layout(game)
    local ins = game.inset
    local availW = game.vw - ins.l - ins.r
    local availH = game.vh - ins.t - ins.b
    local usable = availW - EDGE * 2

    local lay = {}
    lay.cardW = cardWidth()

    local n = #self.cards
    local cols = 1
    while cols < n and lay.cardW * (cols + 1) + GAP * cols <= usable do
        cols = cols + 1
    end
    cols = math.max(cols, 2)
    local rows = math.ceil(n / cols)
    cols = math.ceil(n / rows)
    lay.cols, lay.rows = cols, rows

    local headH = Font.height * HEAD_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    -- A card is four things stacked, and when the screen cannot hold all four it
    -- gives them up in a fixed order: the swatch first, then the line about the
    -- class, and never the name or the box. That order is what each is worth. The
    -- box is the only part you can answer and the name is the only part that says
    -- what you are answering, so they are not negotiable; the page is the richest
    -- of the four and also the one a card can be honest without; and `says`
    -- describes a class four of the subjects share, so on a screen this cramped it
    -- is the same words four times.
    --
    -- Everything except the swatch is a fixed height, so the swatch is simply what
    -- is left over shared between the rows -- and it is all or nothing. A screen
    -- too cramped to give it its floor drops it entirely rather than showing a
    -- two-pixel sliver of ruling, which is not a page: it is a blue line lying to
    -- you about one.
    local function fixedFor(textH)
        return headH + HEAD_GAP + HINT_GAP + hintH
            + rows * (PAD * 2 + textH + BOX_GAP + Scribble.BOX_H)
            + ROW_GAP * (rows - 1)
    end

    local textH = NAME_GAP + Font.height + SAYS_GAP + Font.height
    lay.says = true

    local fixed = fixedFor(textH)
    if fixed > availH then
        lay.says = false
        textH = NAME_GAP + Font.height
        fixed = fixedFor(textH)
    end

    local slack = math.floor((availH - fixed) / rows)
    lay.swatch = slack >= SWATCH_MIN and math.min(slack, SWATCH_MAX) or 0

    lay.cardH = PAD + lay.swatch + textH + PAD

    -- A card and the box under it move as one thing.
    local unit = lay.cardH + BOX_GAP + Scribble.BOX_H
    local gridH = unit * rows + ROW_GAP * (rows - 1)

    local y = 0
    lay.head = y;  y = y + headH + HEAD_GAP
    lay.cards = y; y = y + gridH + HINT_GAP
    lay.hint = y;  y = y + hintH

    local top = math.max(ins.t, math.floor(ins.t + (availH - y) / 2))
    lay.head = lay.head + top
    lay.cards = lay.cards + top
    lay.hint = lay.hint + top

    lay.cx = math.floor(ins.l + availW / 2)

    for i, card in ipairs(self.cards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local inRow = math.min(cols, n - row * cols)
        local rowW = lay.cardW * inRow + GAP * (inRow - 1)

        card.x = math.floor(lay.cx - rowW / 2) + col * (lay.cardW + GAP)
        card.y = lay.cards + row * (unit + ROW_GAP)
        card.w, card.h = lay.cardW, lay.cardH

        self.choice:place(card.box,
            card.x + math.floor((card.w - card.box.w) / 2),
            card.y + card.h + BOX_GAP)
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

-- A press that lands on a card draws the scribble into its box rather than
-- jumping past it, exactly as the keyboard does.
function Timetable:tap(x, y)
    for _, card in ipairs(self.cards) do
        if x >= card.x and x < card.x + card.w
            and y >= card.y and y < card.y + card.h then
            self.choice:autoFill(card.box)
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
    if slot and self.cards[slot] then
        self.choice:autoFill(self.cards[slot].box)
    end
end

--- draw ----------------------------------------------------------------------

function Timetable:prompt()
    if self.choice.armed then
        return Input.usingTouch and "LIFT TO CONFIRM" or "RELEASE TO CONFIRM"
    end
    return "TAP A PAGE OR SCRIBBLE ITS BOX"
end

-- Counted off the cards rather than written out, so a subject added to the book
-- is offered a key without this line having to be remembered. It stops at nine
-- because `keypressed` reads a single digit, so a tenth subject would be
-- scribbled for rather than pressed -- which is the route the screen is built
-- around anyway.
function Timetable:keyHint()
    local keys = {}
    for i = 1, math.min(#self.cards, 9) do keys[i] = tostring(i) end
    return "OR PRESS " .. table.concat(keys, " ")
end

function Timetable:drawCard(i, card)
    local sub = Subjects.list[i]
    local progress = util.clamp(self.t / CARD_TIME, 0, 1)

    -- The card and the box under it answer as one thing, so they warm and flash
    -- as one thing: both borders take their colour from the box.
    local color = Scribble.boxColor(card.box, self.chosen, self.confirmT)

    -- Paper is the one colour that covers what is under it rather than stacking
    -- with it, which is what makes this a card lying on the page rather than a
    -- window in front of it. The swatch is laid on top of that, and is the only
    -- thing on any screen in this game that is a picture of a page rather than a
    -- page: it is drawn after the overprint pass like the rest of the card, so
    -- its ruling is ruling to look at and not ruling to draw on.
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", card.x, card.y, card.w, card.h)
    if self.lay.swatch > 0 then
        Background.drawPatch(sub.key, card.x + PAD, card.y + PAD,
            card.w - PAD * 2, self.lay.swatch)
    end

    Scribble.drawBox(card, progress, color, 20 + i * 3, 0)

    local cx = card.x + card.w / 2
    local y = card.y + PAD + self.lay.swatch + NAME_GAP

    love.graphics.setColor(Palette.ink)
    Font.printCentered(sub.name, cx, y)
    if self.lay.says then
        love.graphics.setColor(Palette.slate)
        Font.printCentered(sub.says, cx, y + Font.height + SAYS_GAP)
    end

    Scribble.drawBox(card.box, progress, color, 40 + i * 3, 0)
    Scribble.drawMarks(card.box.marks, Palette.ink, self.seed, 0)
end

function Timetable:draw(game)
    local lay = self:layout(game)

    -- Written on the page rather than laid over it, so the ruling shows through
    -- the question the same way it shows through a pencil line drawn mid-run --
    -- and the ruling it shows through is the one being answered.
    Overprint.beginPage()
    Background.drawAs(self:pageKey(), 0, 0, game.vw, game.vh)

    Overprint.beginInk()
    self.marks:draw(0)

    Scribble.printBig(HEAD, lay.cx, lay.head, HEAD_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(self:prompt(), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 61 })
        if not Input.usingTouch and not armed then
            Scribble.printBig(self:keyHint(), lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 62 })
        end
    end

    Overprint.finish()

    -- The cards are paper laid on the page, so they come after the pass, exactly
    -- as the draft's do and for the same reason: paper covers what is under it,
    -- and a swatch that had been overprinted would be a page seen through a page.
    for i, card in ipairs(self.cards) do
        self:drawCard(i, card)
    end
end

return Timetable
