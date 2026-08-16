-- The timetable: which page of the book this run is played on.
--
-- It sits between the title screen and the board your character is drawn on,
-- which is the only place it can sit. The subject decides how the page is ruled
-- and the ruling is what the drawing is read against (src/overprint.lua), so
-- picking it after the hero is drawn would mean drawing him against one page and
-- playing him on another.
--
-- Four subjects, four cards, and each card is a piece of the page it offers --
-- read straight off the tile that page is baked into (src/background.lua), so
-- what is on the card is exactly what the run will be played on rather than an
-- illustration of it. Under each is a box, and it is answered the way everything
-- in this game is answered (src/scribble.lua): scribble in it, or tap the card
-- and the scribble is drawn for you.
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
local SWATCH_H = 16    -- the piece of the page itself: two ruled lines, or one
                       -- stave and the gap after it
local NAME_GAP = 3     -- swatch to the subject's name
local SAYS_GAP = 2     -- name to what its class is like
local GAP = 8          -- between one card and the next
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

-- Every card is the width of the widest thing any of them has to say, so the
-- four read as one timetable rather than as four notes of different sizes.
local function cardWidth()
    local w = 0
    for _, sub in ipairs(Subjects.list) do
        w = math.max(w, Font.width(sub.name), Font.width(sub.says))
    end
    return w + PAD * 2
end

-- All four in a row when the page is wide enough for them, and two by two when
-- it is not -- which is a phone held upright, where there is height to spare
-- instead. Never a single column: four cards stacked is taller than any screen
-- this game runs on.
function Timetable:layout(game)
    local ins = game.inset
    local availW = game.vw - ins.l - ins.r
    local availH = game.vh - ins.t - ins.b
    local usable = availW - EDGE * 2

    local lay = {}
    lay.cardW = cardWidth()
    lay.cardH = PAD + SWATCH_H + NAME_GAP + Font.height + SAYS_GAP + Font.height + PAD

    -- A card and the box under it move as one thing.
    local unit = lay.cardH + BOX_GAP + Scribble.BOX_H

    local n = #self.cards
    lay.cols = usable >= lay.cardW * n + GAP * (n - 1) and n or 2
    local rows = math.ceil(n / lay.cols)

    local gridW = lay.cardW * lay.cols + GAP * (lay.cols - 1)
    local gridH = unit * rows + GAP * (rows - 1)

    local headH = Font.height * HEAD_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    local y = 0
    lay.head = y;  y = y + headH + HEAD_GAP
    lay.cards = y; y = y + gridH + HINT_GAP
    lay.hint = y;  y = y + hintH

    local top = math.max(ins.t, math.floor(ins.t + (availH - y) / 2))
    lay.head = lay.head + top
    lay.cards = lay.cards + top
    lay.hint = lay.hint + top

    lay.cx = math.floor(ins.l + availW / 2)

    local left = math.floor(lay.cx - gridW / 2)
    for i, card in ipairs(self.cards) do
        local col = (i - 1) % lay.cols
        local row = math.floor((i - 1) / lay.cols)

        card.x = left + col * (lay.cardW + GAP)
        card.y = lay.cards + row * (unit + GAP)
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
    Background.drawPatch(sub.key, card.x + PAD, card.y + PAD,
        card.w - PAD * 2, SWATCH_H)

    Scribble.drawBox(card, progress, color, 20 + i * 3, 0)

    local cx = card.x + card.w / 2
    local y = card.y + PAD + SWATCH_H + NAME_GAP

    love.graphics.setColor(Palette.ink)
    Font.printCentered(sub.name, cx, y)
    love.graphics.setColor(Palette.slate)
    Font.printCentered(sub.says, cx, y + Font.height + SAYS_GAP)

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
            Scribble.printBig("OR PRESS 1 2 3 4", lay.cx, lay.hint + Font.height + 2, 1,
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
