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

-- The dev toggle (Game:toggleAllTools), keyboard only: a playtest wants a tool
-- without drafting a run to it, and a playtest has a keyboard. The line reads
-- out which way the switch is set, so both strings are part of the card's
-- widest-it-can-ever-be measurement like the three hints above.
local DEV_OFF = "T: EVERY TOOL MAXED, FOR TESTING"
local DEV_ON = "T: HAND THE TEST TOOLS BACK"

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
        Font.width(ASK), Font.width(LIFT), Font.width(RELEASE), Font.width(KEYS),
        Font.width(DEV_OFF), Font.width(DEV_ON))
end

function Pause:layout(game)
    local ins = game.inset
    -- Three lines on a keyboard -- the prompt, the Y/N route and the dev
    -- toggle -- and just the prompt on touch, which has no key to press.
    local hintH = Input.usingTouch and Font.height or Font.height * 3 + 4
    local carryH = Hud.passiveRow(game)

    -- The stack is measured from inside the card, so the padding at the top is
    -- where it starts and the card is everything down to the padding at the
    -- bottom of the hint.
    local lay, y = {}, CARD_PAD_Y
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 9
    lay.boxes = y; y = y + Scribble.BOX_H + 9
    lay.hint = y;  y = y + hintH

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
    if lay.carry then lay.carry = lay.carry + top end

    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.labelY = lay.boxes + math.floor((Scribble.BOX_H - Font.height * LABEL_SCALE) / 2)

    lay.cardW = self:contentWidth() + CARD_PAD_X * 2
    lay.cardX = math.floor(lay.cx - lay.cardW / 2)

    self.choice:layout(lay.cx, lay.boxes)

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
    self.marks:add(x, y)
end

--- update --------------------------------------------------------------------

-- Returns "quit" or "resume" on the frame the answer lands, and nothing at all
-- until then.
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

    local down = Input.pointerDown
    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end)

    -- Armed, not answered: nothing is committed until the pen comes off the
    -- page, so a line that carries on into the other box changes the answer
    -- rather than being too late.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
    end
end

function Pause:keypressed(key)
    if self.phase ~= "asking" then return end

    if key == "y" then
        self.choice:autoFill(self.choice.boxes[1])
    elseif key == "n" then
        self.choice:autoFill(self.choice.boxes[2])
    end
end

--- draw ----------------------------------------------------------------------

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

    -- Once the answer is in, the line has nothing left to ask for: the box
    -- flashing on its own is the whole of the feedback.
    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(self:prompt(), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 51 })
        if not Input.usingTouch and not armed then
            Scribble.printBig(KEYS, lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 52 })
            Scribble.printBig(game.loadout.devTools and DEV_ON or DEV_OFF,
                lay.cx, lay.hint + (Font.height + 2) * 2, 1,
                Palette.graphite, { seed = 53 })
        end
    end
end

return Pause
