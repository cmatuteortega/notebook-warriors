-- The draft.
--
-- Levelling up holds the run and lays three cards on the page, each with a
-- selection box under it, and you pick one exactly the way the title screen is
-- answered (src/scribble.lua): scribble in the box under the card you want --
-- or tap the card itself, which draws the scribble for you the same way the
-- keyboard shortcut does. As everywhere else the answer is armed while the pen
-- is down and committed when it comes off, so a scribble that carries on into
-- the next box changes its mind.
--
-- The cards are the one thing in this game drawn on paper rather than in ink:
-- they are laid *on* the page, they cover the run frozen underneath, and the
-- three of them are the only thing you can do with the page while they are
-- there. Everything else about them is drawn -- a wonky border that warms up as
-- the box under it fills, and the scribble itself, sitting in the box the way
-- ink sits on paper. Ink that missed every box is not an answer, just ink, and
-- goes under the cards and fades.
--
-- One card is not paper: the first level of a tool line, which hands you the
-- tool itself and spends one of the three places on the strip. See `unlocks`.
--
-- What is *in* the cards is none of this file's business: it is handed a list
-- of upgrade lines (src/upgrades.lua) and hands back the id of the one that was
-- circled.

local Palette = require("src.palette")
local Font = require("src.font")
local Sprites = require("src.sprites")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hud = require("src.hud")
local util = require("src.util")

local LevelUp = {}
LevelUp.__index = LevelUp

local HEAD_SCALE = 2
local CARD_MIN_W = 76     -- narrower than this and three of them go in a column
local CARD_MAX_W = 150    -- ... and no wider than this when they do
local GAP = 12            -- between one card and the next: room to draw in
local EDGE = 4            -- ... and a little off the edge of the page
local BOX_GAP = 4         -- between a card and the selection box under it
local PAD = 5             -- card border to what is written inside it
local LINE = Font.height + 2
local ICON = 11

local HEAD_GAP, HINT_GAP = 6, 7
local CARRY_DROP = 8      -- the question, and then -- clear of it, because it
                          -- is not part of it -- what the run is carrying
local CARD_TIME = 0.22    -- the cards drawing themselves on as the draft opens
local CONFIRM = 0.34      -- the circled card flashing before the pick takes hold

function LevelUp.new()
    return setmetatable({ cards = {} }, LevelUp)
end

-- `offer` is the upgrade lines to put on the cards, in order.
function LevelUp:open(game, offer)
    self.offer = offer
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)
    self.wrapped = nil     -- the text, broken to the width the cards ended up

    -- A pointer already down when the level landed -- a pen mid-stroke, which
    -- is the usual way to be levelling up -- is not this screen's to read at
    -- all: it draws nothing and taps nothing until it has been lifted and
    -- pressed afresh.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()

    -- One unlabelled box per card -- the card above it is the label -- placed
    -- under each card by layout.
    local defs = {}
    for i, up in ipairs(offer) do
        defs[i] = { key = up.id }
    end
    self.choice = Scribble.newChoice(defs, 1)

    self.cards = {}
    for i = 1, #offer do
        self.cards[i] = { box = self.choice.boxes[i] }
    end

    -- What level of each line is on offer, read once: the loadout changes the
    -- instant the pick lands, and the card should still say what it said.
    self.levels = {}
    for i, up in ipairs(offer) do
        self.levels[i] = game.loadout:levelOf(up.id) + 1
    end
end

--- layout --------------------------------------------------------------------

-- Greedy, on whole words. The font has no lower case and no comma, so a line of
-- upgrade text is a handful of short words and this never has to be cleverer
-- than it is.
local function wrap(text, width)
    local lines, line = {}, nil

    for word in text:gmatch("%S+") do
        local try = line and (line .. " " .. word) or word
        if not line or Font.width(try) <= width then
            line = try
        else
            lines[#lines + 1] = line
            line = word
        end
    end

    if line then lines[#lines + 1] = line end
    return lines
end

-- Three across when there is width for three, and a column of three when there
-- is not -- which is a phone held upright, where there is height to spare
-- instead. Measured off the safe area minus both margins: the tool column down
-- the right and the weapon column down the left are drawn over the top of all
-- this, and a card underneath either of them is a card you cannot see the whole
-- of. Both are claimed at all times, empty or not, so that the cards sit in the
-- same place at every draft of the run rather than shuffling along the moment
-- the left column has something in it.
function LevelUp:layout(game)
    local ins = game.inset
    local left = ins.l + Hud.leftMargin()
    local availW = game.vw - left - ins.r - Hud.rightMargin()
    local availH = game.vh - ins.t - ins.b

    local usable = availW - EDGE * 2

    local lay = {}
    lay.side = usable >= CARD_MIN_W * 3 + GAP * 2
    lay.cardW = lay.side
        and math.floor((usable - GAP * 2) / 3)
        or math.min(usable, CARD_MAX_W)

    -- The text is re-broken only when the width it has to fit actually changes,
    -- so a window being dragged is the only thing that ever pays for it.
    if self.wrapped ~= lay.cardW then
        self.wrapped = lay.cardW
        self.lines = {}
        local most = 1
        for i, up in ipairs(self.offer) do
            self.lines[i] = wrap(up.levels[self.levels[i]].text, lay.cardW - PAD * 2)
            most = math.max(most, #self.lines[i])
        end
        self.rows = most
    end

    -- All three are the height of the wordiest of them, so they read as a set
    -- of three rather than three separate things.
    lay.cardH = PAD + ICON + 4 + self.rows * LINE - 2 + PAD

    -- A card and the box under it move as one thing.
    local unit = lay.cardH + BOX_GAP + Scribble.BOX_H

    local headH = Font.height * HEAD_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2
    local strip = lay.side and unit or unit * 3 + GAP * 2

    local carryH = Hud.passiveRow(game)

    local y = 0
    lay.head = y;  y = y + headH + HEAD_GAP
    lay.cards = y; y = y + strip + HINT_GAP
    lay.hint = y;  y = y + hintH

    -- Under the question rather than in it: what the run is already carrying is
    -- not one of the three things it is being offered.
    if carryH > 0 then
        y = y + CARRY_DROP
        lay.carry = y
        y = y + carryH
    end

    -- Centred on the cards rather than on the whole stack: the heading above
    -- them is nowhere near as tall as the hint and the carry row below, so
    -- centring the stack parks the cards well above the middle of the page.
    -- The cards are the question; they get the middle.
    local top = math.floor(ins.t + (availH - strip) / 2) - lay.cards
    top = math.min(top, ins.t + availH - y)  -- but the stack stays on the page
    top = math.max(ins.t, top)               -- and the heading wins if it can't
    lay.head = lay.head + top
    lay.cards = lay.cards + top
    lay.hint = lay.hint + top
    if lay.carry then lay.carry = lay.carry + top end

    lay.cx = math.floor(left + availW / 2)

    for i, card in ipairs(self.cards) do
        if lay.side then
            card.x = left + math.floor((availW - (lay.cardW * 3 + GAP * 2)) / 2)
                + (i - 1) * (lay.cardW + GAP)
            card.y = lay.cards
        else
            card.x = left + math.floor((availW - lay.cardW) / 2)
            card.y = lay.cards + (i - 1) * (unit + GAP)
        end
        card.w, card.h = lay.cardW, lay.cardH

        self.choice:place(card.box,
            card.x + math.floor((lay.cardW - card.box.w) / 2),
            card.y + lay.cardH + BOX_GAP)
    end

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

function LevelUp:commit(box)
    self.phase = "confirm"
    self.chosen = box
    self.confirmT = 0
end

-- Ink that lands in a box is the answer and is counted there; ink that misses
-- is just ink on the page.
function LevelUp:mark(x, y, quiet)
    if self.choice:mark(x, y, quiet) then return end
    self.marks:add(x, y)
end

-- A press that lands on a card is a pick of it. The tap draws the scribble in
-- the card's box rather than jumping past it, exactly as the keyboard does, so
-- the card is still answered the only way anything here is answered.
function LevelUp:tap(x, y)
    for _, card in ipairs(self.cards) do
        if x >= card.x and x < card.x + card.w
            and y >= card.y and y < card.y + card.h then
            self.choice:autoFill(card.box)
            return
        end
    end
end

-- Returns the id of the upgrade that was circled, on the frame the pick takes
-- hold, and nothing at all until then.
function LevelUp:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then return self.chosen.key end
        return
    end

    -- The keyboard and a tap on a card both draw the scribble rather than
    -- jumping past it, and there is no pen to lift, so that answer stands as
    -- soon as the box fills.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    -- The press that was already down when the screen opened stays invisible
    -- until it is lifted; only a fresh press draws or taps here.
    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end,
        function(px, py) self:tap(px, py) end)

    -- Armed, not answered: nothing is picked until the pen comes off the page.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
    end
end

function LevelUp:keypressed(key)
    if self.phase ~= "asking" then return end

    local slot = tonumber(key)
    if slot and self.cards[slot] then
        self.choice:autoFill(self.cards[slot].box)
    end
end

--- draw ----------------------------------------------------------------------

function LevelUp:prompt()
    if self.choice.armed then
        return Input.usingTouch and "LIFT TO CONFIRM" or "RELEASE TO CONFIRM"
    end
    return "TAP A CARD OR SCRIBBLE ITS BOX"
end

-- Whether this card hands you a tool rather than improving something.
--
-- It is the one pick in the draft that costs a run something it does not get
-- back: a tool line's first level puts the tool on the strip, and the strip has
-- three places on it (`Loadout.SLOTS`) one of which is gone before the run
-- starts. Every other card -- a passive, a weapon, a tool getting better -- is
-- a run being added to. This one is a run being decided.
--
-- Which is why it is said in the colour of the card and not in the words on it.
-- The words are read one card at a time and this has to be read before that:
-- three cards go down, one of them is not the colour of the other two, and you
-- know which one you are choosing *about* before you have read a line.
local function unlocks(up, level)
    return level == 1 and up.kind == "tool"
end

function LevelUp:drawCard(i, card)
    local up = self.offer[i]
    local level = self.levels[i]

    -- The card and the box under it answer as one thing, so they warm and
    -- flash as one thing: both borders take their colour from the box.
    local color = Scribble.boxColor(card.box, self.chosen, self.confirmT)

    -- Paper is the one colour that covers what is under it rather than stacking
    -- with it, which is what makes this a card lying on the page and not a
    -- window in front of it. Sky is a card cut from other paper, and covers
    -- exactly as flatly -- the draft is drawn after the overprint pass, so
    -- neither of them lets the ruling through.
    --
    -- Sky rather than blush, which is the other light fill in the palette: the
    -- border warms slate -> blue -> red as the box fills, and blush would
    -- swallow the red -- the step that says the answer has landed. Sky only
    -- costs the blue halfway step, which is the one you never stop on.
    love.graphics.setColor(unlocks(up, level) and Palette.sky or Palette.paper)
    love.graphics.rectangle("fill", card.x, card.y, card.w, card.h)

    Scribble.drawBox(card, util.clamp(self.t / CARD_TIME, 0, 1), color, 20 + i * 3, 0)

    love.graphics.setColor(1, 1, 1)
    Sprites.icons[up.icon]:draw(card.x + PAD + ICON / 2, card.y + PAD + ICON / 2)

    local textX = card.x + PAD + ICON + 2
    love.graphics.setColor(Palette.ink)
    Font.print(up.name, textX, card.y + PAD)

    -- A line you have never taken says so, because the first level of one is
    -- the only pick that changes what the run *is* rather than what it is like.
    local text = level == 1 and "NEW" or ("LV " .. level)
    love.graphics.setColor(level == 1 and Palette.red or Palette.slate)
    Font.print(text, textX, card.y + PAD + 6)

    -- And a line this pick *finishes* says that too, in words rather than in
    -- the colour of the card: the colour is spoken for by the one pick that
    -- costs a run something it does not get back (see `unlocks`), and a last
    -- level costs nothing -- it is a run being added to like any other card.
    -- There is no third card colour to say it in either, since sky is taken and
    -- blush would swallow the red the border warms to.
    --
    -- Said beside the level rather than instead of it, because which level it
    -- is and whether it is the last one are two different things a card is
    -- being asked. On the pen and the stapler they are the same thing -- one
    -- level, so NEW MAX -- and that is the card this is really for: it says the
    -- tool has nothing after it *before* you spend one of three permanent slots
    -- reaching it.
    if level == #up.levels then
        love.graphics.setColor(Palette.red)
        Font.print("MAX", textX + Font.width(text .. " "), card.y + PAD + 6)
    end

    love.graphics.setColor(Palette.slate)
    for j, line in ipairs(self.lines[i]) do
        Font.print(line, card.x + PAD, card.y + PAD + ICON + 4 + (j - 1) * LINE)
    end

    -- The box, drawn on over the same quarter second as the card above it, and
    -- the scribble sitting in it the way ink sits on paper.
    Scribble.drawBox(card.box, util.clamp(self.t / CARD_TIME, 0, 1), color,
        40 + i * 3, 0)
    Scribble.drawMarks(card.box.marks, Palette.ink, self.seed, 0)
end

function LevelUp:draw(game)
    local lay = self:layout(game)

    -- Furniture first, under the ink: the weapon column is read the same way
    -- the tool column on the far side is, and that one is drawn before this
    -- screen ever gets the page.
    Hud.drawWeapons(game)
    if lay.carry then Hud.drawPassives(game, lay.cx, lay.carry) end

    -- Under the cards: ink that missed is the page, and the cards are on it.
    self.marks:draw(0)

    Scribble.printBig("LEVEL " .. game.player.level, lay.cx, lay.head, HEAD_SCALE,
        Palette.red, { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    for i, card in ipairs(self.cards) do
        self:drawCard(i, card)
    end

    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(self:prompt(), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 61 })
        if not Input.usingTouch and not armed then
            Scribble.printBig("OR PRESS 1 2 3", lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 62 })
        end
    end
end

return LevelUp
