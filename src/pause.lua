-- The pause screen.
--
-- Holding the run puts a question on the page, and it is asked the way the
-- title screen asks its own: a box you scribble in (src/scribble.lua). QUIT?
-- YES or NO. Drawing in YES closes the run and hands the page back to the title
-- screen; drawing in NO lets it go again, and so does the button in the corner.
--
-- The question is asked on a card, unlike the title screen's, which is written
-- straight on the page. The difference is what is underneath: a title screen is
-- a page with a doodle walking round it, and a paused run is whatever was
-- happening at the moment you stopped it -- a horde, a wall of ink, half an
-- eraser sweep -- and lettering laid over that is lettering you cannot read. The
-- card is paper, which is the one colour that covers what is under it rather
-- than stacking with it, so it really is a card lying on the page.
--
-- Under the question is the one thing on the card that is not part of it: DEV,
-- a switch rather than an answer. Scribbling it lends the run every tool in the
-- game and scribbling it again takes them back, and either way the card stays
-- up -- so the ink comes straight back out of the box the way it does out of the
-- studio's RESET, because a switch has to be throwable twice. `T` throws it from
-- the keyboard, filling the box in rather than jumping past it. It is set apart
-- from YES and NO by a gap and by being small: the card is asking whether to
-- quit, and this is not an answer to that.
--
-- Everything outside the card is still page. The whole of it stays drawable,
-- and ink that misses the boxes is not an answer, just ink, and fades off
-- exactly as it does on the title screen. What the run is carrying is laid out
-- under the card by src/hud.lua, in the same boxes the tools are drawn in.

local Palette = require("src.palette")
local Font = require("src.font")
local Input = require("src.input")
local Hud = require("src.hud")
local Scribble = require("src.scribble")
local util = require("src.util")

local Pause = {}
Pause.__index = Pause

local HEAD, TITLE = "PAUSED", "QUIT?"

-- Hoisted, because the card behind them has to be as wide as the widest thing
-- that can ever appear on it rather than as wide as what is on it now: a card
-- that grew a few pixels the moment a box armed would be a card that twitched.
local ASK = "SCRIBBLE IN A BOX"
local LIFT, RELEASE = "LIFT TO CONFIRM", "RELEASE TO CONFIRM"
local KEYS = "OR PRESS Y OR N"

-- The switch under the question. Drawn at 1 rather than at LABEL_SCALE because
-- it is not one of the answers and should not read as one.
local DEV = "DEV"
local DEV_ON, DEV_OFF = "ON", "OFF"
local DEV_SCALE = 1
local DEV_GAP = 4      -- the box to the word saying which way it is thrown
local DEV_DROP = 9     -- the question above it to the switch

local LABEL_SCALE = 2
local BOX_TIME = 0.25  -- the card and the boxes drawing themselves on
local CONFIRM = 0.32   -- the answered box flashing before the answer takes hold
local CARD_PAD_X, CARD_PAD_Y = 8, 7
local CARRY_DROP = 16  -- the card, and then -- well clear of it, because it is
                       -- not part of the question -- what the run is carrying

function Pause.new()
    local self = setmetatable({}, Pause)
    self:open()
    return self
end

-- Every pause is a fresh question: ink drawn into a box last time is not still
-- sitting there deciding this one.
function Pause:open()
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer already down when the run was held -- a pen mid-stroke, or the
    -- other hand still on the page -- is not a press of this screen. Only one
    -- that arrives after it counts.
    self.pen = Scribble.newPen(Input.pointerDown)

    self.choice = Scribble.newChoice({
        { key = "yes", label = "YES" },
        { key = "no", label = "NO" },
    }, LABEL_SCALE)

    -- A box of its own rather than a third one in the strip above: that strip is
    -- the answer to QUIT?, and a box in it that answers something else would be
    -- a box that quits the run when it is misread.
    self.switch = Scribble.newChoice({ { key = "dev", label = DEV } }, DEV_SCALE)
end

-- Whichever way it is thrown, so the row is measured and centred on the wider of
-- the two words and does not shift under the finger that just threw it.
local function devStateW()
    return math.max(Font.width(DEV_ON), Font.width(DEV_OFF))
end

-- The line under the boxes says what the screen is waiting for, which is the
-- only warning that lifting is what commits an answer.
function Pause:prompt()
    if self.choice.armed then
        return Input.usingTouch and LIFT or RELEASE
    end
    return ASK
end

-- Stacked top to bottom, then centred in the safe area, so it lands right on
-- whatever shape of screen the canvas ended up being.
-- The widest thing the card ever has to hold. The hint swaps between three
-- lines of different lengths as the question is answered, so all three are
-- measured rather than whichever is up.
function Pause:contentWidth()
    return math.max(
        Font.width(HEAD),
        Font.width(TITLE) * LABEL_SCALE,
        self.choice:stripWidth(),
        self:devRowW(),
        Font.width(ASK), Font.width(LIFT), Font.width(RELEASE), Font.width(KEYS))
end

-- Label, box and the word after it, as one row.
function Pause:devRowW()
    return self.switch:stripWidth() + DEV_GAP + devStateW()
end

function Pause:layout(game)
    local ins = game.inset
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2
    local carryH = Hud.passiveRow(game)

    -- The stack is measured from inside the card, so the padding at the top is
    -- where it starts and the card is everything down to the padding at the
    -- bottom of the hint.
    local lay, y = {}, CARD_PAD_Y
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 9
    lay.boxes = y; y = y + Scribble.BOX_H + 9
    lay.hint = y;  y = y + hintH + DEV_DROP
    lay.dev = y;   y = y + Scribble.BOX_H

    lay.cardH = y + CARD_PAD_Y
    y = lay.cardH

    -- Under the card rather than on it: the run's passives are not something
    -- the screen is asking about, they are what it is holding.
    if carryH > 0 then
        y = y + CARRY_DROP
        lay.carry = y
        y = y + carryH
    end

    local top = math.floor(ins.t + (game.vh - ins.t - ins.b - y) / 2)
    lay.cardY = top
    lay.head = lay.head + top
    lay.title = lay.title + top
    lay.boxes = lay.boxes + top
    lay.hint = lay.hint + top
    lay.dev = lay.dev + top
    if lay.carry then lay.carry = lay.carry + top end

    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.labelY = lay.boxes + math.floor((Scribble.BOX_H - Font.height * LABEL_SCALE) / 2)

    lay.cardW = self:contentWidth() + CARD_PAD_X * 2
    lay.cardX = math.floor(lay.cx - lay.cardW / 2)

    self.choice:layout(lay.cx, lay.boxes)

    -- The strip is centred on its own middle, so it is pushed left by half of
    -- what stands to the right of it to centre the row as a whole.
    self.switch:layout(lay.cx - (DEV_GAP + devStateW()) / 2, lay.dev)
    lay.devLabelY = lay.dev + math.floor((Scribble.BOX_H - Font.height * DEV_SCALE) / 2)

    self.lay = lay
    return lay
end

function Pause:commit(box)
    self.phase = "confirm"
    self.chosen = box
    self.confirmT = 0
end

-- Ink that lands in a box is the answer and is counted there; ink that misses
-- is just ink on the page.
function Pause:mark(x, y, quiet)
    if self.choice:mark(x, y, quiet) then return end
    if self.switch:mark(x, y, quiet) then return end
    self.marks:add(x, y)
end

--- update --------------------------------------------------------------------

-- Returns "quit" or "resume" on the frame the answer lands, "dev" on the frame
-- the switch is thrown, and nothing at all until then. The first two close the
-- screen and the third does not, which is the whole difference between an answer
-- and a switch.
function Pause:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then
            return self.chosen.key == "yes" and "quit" or "resume"
        end
        return
    end

    -- The keyboard fills a box in rather than jumping past it, and there is no
    -- pen to lift, so that answer stands as soon as the scribble lands.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    -- The switch is filled in on the same terms, and `T` runs it the same way.
    local thrown = self.switch:update(dt)

    local down = Input.pointerDown
    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end)

    -- Armed, not answered: nothing is committed until the pen comes off the
    -- page, so a line that carries on into the other box changes the answer
    -- rather than being too late.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
        return
    end

    -- Same bargain for the switch -- ink arms it, lifting throws it -- and then
    -- the ink comes straight back out, because it acts on the screen it is on
    -- rather than closing it and has to be throwable again. Exactly what the
    -- studio's RESET does, for exactly the same reason.
    if not thrown and self.switch.armed and not down then
        thrown = self.switch.armed
    end
    if thrown then
        self.switch:clear(thrown)
        return "dev"
    end
end

function Pause:keypressed(key)
    if self.phase ~= "asking" then return end

    if key == "y" then
        self.choice:autoFill(self.choice.boxes[1])
    elseif key == "n" then
        self.choice:autoFill(self.choice.boxes[2])
    elseif key == "t" then
        self.switch:autoFill(self.switch.boxes[1])
    end
end

--- draw ----------------------------------------------------------------------

-- The switch, and the word saying which way it is thrown. The word is the whole
-- of the state: the ink is wiped out of the box the moment it is thrown, so
-- there is nothing else on the card that could say.
--
-- It is read straight off the run rather than kept here, because the run is
-- where it lives -- there is no second copy of it to fall out of step.
function Pause:drawSwitch(game, lay, progress)
    local box = self.switch.boxes[1]
    local on = game.loadout and game.loadout.dev

    -- Never `chosen`: it is not an answer and never flashes one in. What warms
    -- its border is the ink going into it, the same as everywhere else.
    local color = Scribble.boxColor(box, nil, 0)

    Scribble.printBig(box.label, box.labelCx, lay.devLabelY, DEV_SCALE,
        Palette.slate, { shadow = Palette.paper, seed = 61 })
    Scribble.drawBox(box, progress, color, 20, 0)
    Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)

    -- Red for lent, grey for not: the same red the tool counter goes when the
    -- strip is full, which is the other place the margin says the run is
    -- carrying as much as it can. Grey rather than slate because OFF is the
    -- resting state and should sit back on the card, not read as a live label.
    Scribble.printBig(on and DEV_ON or DEV_OFF,
        box.x + box.w + DEV_GAP + devStateW() / 2, lay.devLabelY, DEV_SCALE,
        on and Palette.red or Palette.graphite, { seed = 62 })
end

function Pause:draw(game)
    local lay = self:layout(game)

    -- Furniture first, under the ink: the weapon column is read the same way
    -- the tool column on the far side is, and that one is drawn before this
    -- screen ever gets the page.
    Hud.drawWeapons(game)
    if lay.carry then Hud.drawPassives(game, lay.cx, lay.carry) end

    self.marks:draw(0)

    local progress = util.clamp(self.t / BOX_TIME, 0, 1)

    -- The card the question is asked on. The page underneath is a run held
    -- mid-panic and can be anything at all -- a horde, a wall of ink, an
    -- eraser sweep -- and lettering laid straight over that is lettering you
    -- cannot read. Paper is the one colour that covers what is under it rather
    -- than stacking with it, so a filled rectangle of it really is a card lying
    -- on the page, and the border is drawn on the same wonky line and over the
    -- same quarter second as the boxes inside it.
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", lay.cardX, lay.cardY, lay.cardW, lay.cardH)
    Scribble.drawBox(
        { x = lay.cardX, y = lay.cardY, w = lay.cardW, h = lay.cardH },
        progress, Palette.slate, 7, 0)

    love.graphics.setColor(Palette.slate)
    Font.printCentered(HEAD, lay.cx, lay.head)

    -- Asking, in a hand that can't keep still. The shadow is what stops the
    -- lettering reading as flat against its own card.
    local pulse = math.sin(self.t * 3.4) > 0
    Scribble.printBig(TITLE, lay.cx, lay.title, LABEL_SCALE,
        pulse and Palette.ink or Palette.slate,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 7 })

    for i, box in ipairs(self.choice.boxes) do
        local color = Scribble.boxColor(box, self.chosen, self.confirmT)

        Scribble.printBig(box.label, box.labelCx, lay.labelY, LABEL_SCALE, color,
            { shadow = Palette.paper, wobble = true, t = self.t, seed = 30 + i * 5 })
        Scribble.drawBox(box, progress, color, 10 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
    end

    self:drawSwitch(game, lay, progress)

    -- Once the answer is in, the line has nothing left to ask for: the box
    -- flashing on its own is the whole of the feedback.
    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(self:prompt(), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 51 })
        if not Input.usingTouch and not armed then
            Scribble.printBig(KEYS, lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 52 })
        end
    end
end

return Pause
