-- The draft.
--
-- Levelling up holds the run and lays three cards on the page, and you circle
-- the one you want. It is the same asking the rest of the game does
-- (src/scribble.lua) with the one mechanic that suits a question with three
-- answers instead of two: a box is filled in, a card is *gone round*. Nine of
-- the twelve sectors of the ring about a card have to have been drawn in, so a
-- loop answers and a line down one side of it does not, and -- as everywhere
-- else -- the answer is armed while the pen is down and committed when it comes
-- off, so a loop that carries on round the next card changes its mind.
--
-- The cards are the one thing in this game drawn on paper rather than in ink:
-- they are laid *on* the page, they cover the run frozen underneath, and the
-- three of them are the only thing you can do with the page while they are
-- there. Everything else about them is drawn -- a wonky border that warms up as
-- you go round it, and the loop you drew, sitting on top of the card the way
-- ink sits on paper. Ink that missed every card is not an answer, just ink, and
-- goes under them and fades.
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
local EDGE = 4            -- ... and the same off the edge of the page, so the
                          -- loop round the outermost card has somewhere to go
local PAD = 5             -- card border to what is written inside it
local LINE = Font.height + 2
local ICON = 11

local HEAD_GAP, HINT_GAP = 6, 7
local CARRY_DROP = 16     -- the question, and then -- well clear of it, because
                          -- it is not part of it -- what the run is carrying
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
    -- is the usual way to be levelling up -- is not a press of this screen.
    self.pen = Scribble.newPen(Input.pointerDown)

    local defs = {}
    for i, up in ipairs(offer) do
        defs[i] = { key = up.id }
    end
    self.circling = Scribble.newCircling(defs)
    self.cards = self.circling.cards

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

    local headH = Font.height * HEAD_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2
    local strip = lay.side and lay.cardH or lay.cardH * 3 + GAP * 2

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

    local top = math.max(ins.t, math.floor(ins.t + (availH - y) / 2))
    lay.head = lay.head + top
    lay.cards = lay.cards + top
    lay.hint = lay.hint + top
    if lay.carry then lay.carry = lay.carry + top end

    lay.cx = math.floor(left + availW / 2)

    for i, card in ipairs(self.cards) do
        if lay.side then
            local x = left + math.floor((availW - (lay.cardW * 3 + GAP * 2)) / 2)
            self.circling:place(card, x + (i - 1) * (lay.cardW + GAP),
                lay.cards, lay.cardW, lay.cardH)
        else
            self.circling:place(card, left + math.floor((availW - lay.cardW) / 2),
                lay.cards + (i - 1) * (lay.cardH + GAP), lay.cardW, lay.cardH)
        end
    end

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

function LevelUp:commit(card)
    self.phase = "confirm"
    self.chosen = card
    self.confirmT = 0
end

-- Ink that goes round a card is the answer and is counted there; ink that
-- misses is just ink on the page.
function LevelUp:mark(x, y, quiet)
    if self.circling:mark(x, y, quiet) then return end
    self.marks:add(x, y)
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

    -- The keyboard draws the loop rather than jumping past it, and there is no
    -- pen to lift, so that answer stands as soon as the loop closes.
    local looped = self.circling:update(dt)
    if looped then
        self:commit(looped)
        return
    end

    local down = Input.pointerDown
    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end)

    -- Armed, not answered: nothing is picked until the pen comes off the page.
    if self.circling.armed and not down then
        self:commit(self.circling.armed)
    end
end

function LevelUp:keypressed(key)
    if self.phase ~= "asking" then return end

    local slot = tonumber(key)
    if slot and self.cards[slot] then
        self.circling:autoCircle(self.cards[slot])
    end
end

--- draw ----------------------------------------------------------------------

function LevelUp:prompt()
    if self.circling.armed then
        return Input.usingTouch and "LIFT TO CONFIRM" or "RELEASE TO CONFIRM"
    end
    return "CIRCLE ONE"
end

function LevelUp:drawCard(i, card)
    local up = self.offer[i]
    local color = Scribble.boxColor(card, self.chosen, self.confirmT)

    -- Paper is the one colour that covers what is under it rather than stacking
    -- with it, which is what makes this a card lying on the page and not a
    -- window in front of it.
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", card.x, card.y, card.w, card.h)

    Scribble.drawBox(card, util.clamp(self.t / CARD_TIME, 0, 1), color, 20 + i * 3, 0)

    love.graphics.setColor(1, 1, 1)
    Sprites.icons[up.icon]:draw(card.x + PAD + ICON / 2, card.y + PAD + ICON / 2)

    local textX = card.x + PAD + ICON + 2
    love.graphics.setColor(Palette.ink)
    Font.print(up.name, textX, card.y + PAD)

    -- A line you have never taken says so, because the first level of one is
    -- the only pick that changes what the run *is* rather than what it is like.
    local level = self.levels[i]
    love.graphics.setColor(level == 1 and Palette.red or Palette.slate)
    Font.print(level == 1 and "NEW" or ("LV " .. level), textX, card.y + PAD + 6)

    love.graphics.setColor(Palette.slate)
    for j, line in ipairs(self.lines[i]) do
        Font.print(line, card.x + PAD, card.y + PAD + ICON + 4 + (j - 1) * LINE)
    end
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

    -- The loop goes on top of the card it went round, the way ink sits on
    -- paper. It is drawn after all three so a loop that reaches across the gap
    -- is not cut off by the card next door.
    for _, card in ipairs(self.cards) do
        Scribble.drawMarks(card.marks, Palette.ink, self.seed, 0)
    end

    if self.phase == "asking" then
        local armed = self.circling.armed ~= nil

        Scribble.printBig(self:prompt(), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 61 })
        if not Input.usingTouch and not armed then
            Scribble.printBig("OR PRESS 1 2 3", lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 62 })
        end
    end
end

return LevelUp
