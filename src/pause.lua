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
local Sfx = require("src.sfx")
local I18n = require("src.i18n")
local Dev = require("src.dev")
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
local HINT_LEAD = 2    -- one hint line to the next

-- The dev toggle (Game:toggleDev). Two switches rather than one, because the two
-- kinds a run carries are not looked at the same way: a tool is judged by what
-- your hand does with it, and a page already carrying every weapon is a page
-- where nothing your hand does can be seen. A playtest borrows the half it is
-- looking at.
--
-- **None of it is drawn unless the book has been asked for it** (`Dev.showing`,
-- src/dev.lua): no boxes on touch, no lines on a keyboard, and the keys do
-- nothing. A run held mid-panic is a question about quitting, and a stranger
-- pausing this game finds exactly that question and nothing else. The card is
-- measured either way round -- it is `contentWidth` and `layout` that ask, so
-- the switches cost a hidden card no width and no height at all.
--
-- One row each, and the row is the whole of the feature: the key that throws it
-- on a keyboard, the label on its box on touch, and the line that reads out
-- which way it is set. `kind` is what Game:toggleDev is handed and what
-- Loadout:grant filters the catalogue on, so a third kind worth lending is a
-- third row here and nothing else anywhere. Both of each row's lines are part of
-- the card's widest-it-can-ever-be measurement, like the hints above.
local DEV = {
    { kind = "tool", key = "t", label = "TOOLS",
      off = "T: EVERY TOOL MAXED", on = "T: HAND THE TOOLS BACK" },
    { kind = "weapon", key = "w", label = "WEAPONS",
      off = "W: EVERY WEAPON MAXED", on = "W: HAND THE WEAPONS BACK" },
}

-- Read by src/game.lua's keypressed, which throws these by key rather than
-- keeping a second list of its own.
Pause.DEV = DEV

-- The same switches on touch, where there is no key to press and the lines above
-- are therefore not drawn at all -- which left a phone with no way to reach the
-- toggle, and a phone is the thing most worth playtesting on. So they become what
-- every other question on this screen already is: boxes you scribble in.
--
-- Small, and set apart from YES and NO by a gap, because neither is an answer to
-- QUIT? -- and boxes of their own rather than more in that strip, since a box in
-- the strip that did something other than answer would be a box that ends the run
-- when it is misread. The word beside each says which way that switch is set,
-- exactly as the keyboard's lines do.
--
-- Strung out in one row rather than stacked, even though a stack would read
-- better: the canvas is 180 game pixels tall and only ever wider, so height is
-- the scarce half of the card and a second row of boxes is 20 of it plus a gap,
-- where a second unit alongside costs width the card has to spare.
local DEV_STATE_ON, DEV_STATE_OFF = "ON", "OFF"
local DEV_SCALE = 1
local DEV_GAP = 4      -- a box to the word beside it
local DEV_SPLIT = 10   -- one switch's word to the next switch's label
local DEV_DROP = 7     -- the hint above them to the row

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

    -- Built either way and laid out only on touch, so nothing has to be made
    -- half way through a pause if the input changes hands. One box per row, keyed
    -- by the kind it lends, which is what comes back out of `update`.
    local defs = {}
    for i, row in ipairs(DEV) do
        defs[i] = { key = row.kind, label = row.label }
    end
    self.switch = Scribble.newChoice(defs, DEV_SCALE)
end

-- Measured on the wider of the two words, so the row does not shift under the
-- finger that just threw a switch.
local function devStateW()
    return math.max(Font.width(I18n.t(DEV_STATE_ON)),
                    Font.width(I18n.t(DEV_STATE_OFF)))
end

-- One switch's share of the touch row: its label, its box, and the word that
-- reads out its state. Measured off the label as it will be *drawn*, since the
-- Spanish words are not the English ones' width.
local function devUnitW(box)
    return Font.width(Scribble.label(box)) * DEV_SCALE
        + Scribble.LABEL_GAP + box.w + DEV_GAP + devStateW()
end

-- And the whole row, which is what the card is measured against on touch.
function Pause:devRowWidth()
    local w = -DEV_SPLIT
    for _, box in ipairs(self.switch.boxes) do
        w = w + devUnitW(box) + DEV_SPLIT
    end
    return w
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
--
-- The dev switches are measured for the input that can actually reach them, and
-- only while they are on the card at all: the row of boxes is wider than either
-- of the lines that replaces it, and a desktop card padded out for boxes it
-- never draws would be a card with a hole in it. The
-- card already changes height when the input changes hands (see `layout`), so it
-- may change width there too -- what it may never do is change while a question
-- on it is being answered, which is what all the rest of this measures for.
function Pause:contentWidth()
    local dev = 0
    if Dev.showing() then
        if Input.usingTouch then
            dev = self:devRowWidth()
        else
            for _, row in ipairs(DEV) do
                dev = math.max(dev, Font.width(I18n.t(row.off)),
                                    Font.width(I18n.t(row.on)))
            end
        end
    end

    return math.max(
        Font.width(I18n.t(HEAD)),
        Font.width(I18n.t(TITLE)) * LABEL_SCALE,
        self.choice:stripWidth(),
        Font.width(I18n.t(ASK)), Font.width(I18n.t(LIFT)),
        Font.width(I18n.t(RELEASE)), Font.width(I18n.t(KEYS)),
        dev)
end

function Pause:layout(game)
    local ins = game.inset
    -- The prompt, the Y/N route and -- once the book has been asked for them --
    -- a line per dev switch on a keyboard, and just the prompt on touch, which
    -- has no keys to press.
    local hintH = Font.height
    if not Input.usingTouch then
        local lines = 2 + (Dev.showing() and #DEV or 0)
        hintH = Font.height * lines + (lines - 1) * HINT_LEAD
    end
    local carryH = Hud.passiveRow(game)

    -- The stack is measured from inside the card, so the padding at the top is
    -- where it starts and the card is everything down to the padding at the
    -- bottom of the hint.
    local lay, y = {}, CARD_PAD_Y
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 9
    lay.boxes = y; y = y + Scribble.BOX_H + 9
    lay.hint = y;  y = y + hintH

    -- Touch only, and what the card is measured against there rather than the
    -- keyboard's lines (see `contentWidth`).
    if Input.usingTouch and Dev.showing() then
        y = y + DEV_DROP
        lay.dev = y
        y = y + Scribble.BOX_H
    end

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
    if lay.dev then lay.dev = lay.dev + top end
    if lay.carry then lay.carry = lay.carry + top end

    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.labelY = lay.boxes + math.floor((Scribble.BOX_H - Font.height * LABEL_SCALE) / 2)

    lay.cardW = self:contentWidth() + CARD_PAD_X * 2
    lay.cardX = math.floor(lay.cx - lay.cardW / 2)

    self.choice:layout(lay.cx, lay.boxes)

    -- Placed by hand rather than through `Choice:layout`, since a switch is a
    -- label, a box *and* the word that reads out its state, and the strip layout
    -- knows about the first two. Each unit is walked left to right off its own
    -- width, so a label the translation made longer moves what follows it rather
    -- than growing under it.
    if lay.dev then
        local x = math.floor(lay.cx - self:devRowWidth() / 2)
        for _, box in ipairs(self.switch.boxes) do
            box.labelW = Font.width(Scribble.label(box)) * DEV_SCALE
            box.labelCx = x + box.labelW / 2
            self.switch:place(box, x + box.labelW + Scribble.LABEL_GAP, lay.dev)
            x = x + devUnitW(box) + DEV_SPLIT
        end
        lay.devLabelY = lay.dev
            + math.floor((Scribble.BOX_H - Font.height * DEV_SCALE) / 2)
    end

    self.lay = lay
    return lay
end

function Pause:commit(box)
    self.phase = "confirm"
    Sfx.play("accept")
    self.chosen = box
    self.confirmT = 0
end

-- Ink that lands in a box is the answer and is counted there; ink that misses
-- is just ink on the page.
-- The switch is only tested when it is actually laid out, so on a keyboard its
-- boxes cannot quietly swallow ink at wherever a touch layout last put them.
function Pause:mark(x, y, quiet)
    -- Ink in a box, ink in the switch or ink on the card: all three are a line
    -- being laid, which is what the pen's swish asks about.
    if self.choice:mark(x, y, quiet) then return true end
    if self.lay and self.lay.dev and self.switch:mark(x, y, quiet) then
        return true
    end
    self.marks:add(x, y)
    return true
end

--- update --------------------------------------------------------------------

-- Returns "quit" or "resume" on the frame the answer lands, and "dev" plus the
-- kind of the switch that was thrown on the frame a touch switch is thrown, and
-- nothing at all until then. The first two close the screen and the third does
-- not, which is the whole difference between an answer and a switch.
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
    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end)

    -- Armed, not answered: nothing is committed until the pen comes off the
    -- page, so a line that carries on into the other box changes the answer
    -- rather than being too late.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
        return
    end

    -- The switches make the same bargain -- ink arms one, lifting throws it -- but
    -- they act on the screen they are on rather than closing it, so the ink comes
    -- straight back out and it can be thrown again. Exactly what the studio's
    -- RESET does, for exactly the same reason. Only one can be armed at a time,
    -- since a stroke running on into the other box changes which -- the same rule
    -- YES and NO are under, and here it means a line drawn across both throws the
    -- one it ended in rather than both.
    if self.lay.dev and self.switch.armed and not down then
        local box = self.switch.armed
        self.switch:clear(box)
        Sfx.play("accept")
        return "dev", box.key
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

-- The touch switches, and the word beside each saying which way it is set. The
-- word is the whole of the state: the ink is wiped out of the box the moment a
-- switch is thrown, so there is nothing else there that could say. It is read
-- straight off the run -- `Loadout:lent` per kind -- rather than kept by this
-- screen, so there is no second copy of it to fall out of step.
function Pause:drawSwitch(game, lay, progress)
    for i, box in ipairs(self.switch.boxes) do
        local on = game.loadout:lent(box.key)

        -- Never `chosen`: neither is an answer and neither ever flashes one in.
        -- What warms a border is the ink going into it, the same as every box
        -- here.
        Scribble.printBig(Scribble.label(box), box.labelCx, lay.devLabelY,
            DEV_SCALE, Palette.slate, { shadow = Palette.paper, seed = 60 + i })
        Scribble.drawBox(box, progress, Scribble.boxColor(box, nil, 0), 20 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)

        -- Red while that half is lent, grey while it is not: the same red the
        -- slot counters go when a switch pushes them past their cap, which is the
        -- other place a held screen says the run is carrying more than it
        -- drafted.
        Scribble.printBig(I18n.t(on and DEV_STATE_ON or DEV_STATE_OFF),
            box.x + box.w + DEV_GAP + devStateW() / 2, lay.devLabelY, DEV_SCALE,
            on and Palette.red or Palette.graphite, { seed = 70 + i })
    end
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
    Font.printCentered(I18n.t(HEAD), lay.cx, lay.head)

    -- Asking, in a hand that can't keep still. The shadow is what stops the
    -- lettering reading as flat against its own card.
    local pulse = math.sin(self.t * 3.4) > 0
    Scribble.printBig(I18n.t(TITLE), lay.cx, lay.title, LABEL_SCALE,
        pulse and Palette.ink or Palette.slate,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 7 })

    for i, box in ipairs(self.choice.boxes) do
        local color = Scribble.boxColor(box, self.chosen, self.confirmT)

        Scribble.printBig(Scribble.label(box), box.labelCx, lay.labelY,
            LABEL_SCALE, color,
            { shadow = Palette.paper, wobble = true, t = self.t, seed = 30 + i * 5 })
        Scribble.drawBox(box, progress, color, 10 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
    end

    -- Once the answer is in, the line has nothing left to ask for: the box
    -- flashing on its own is the whole of the feedback.
    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(I18n.t(self:prompt()), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 51 })
        if not Input.usingTouch and not armed then
            local line = Font.height + HINT_LEAD
            Scribble.printBig(I18n.t(KEYS), lay.cx, lay.hint + line, 1,
                Palette.graphite, { seed = 52 })
            -- One line per switch, in the order the rows are written, each
            -- reading out which way its own half is set -- and none at all until
            -- the book has been asked for them, which is what `layout` already
            -- measured the hint for.
            if Dev.showing() then
                for i, row in ipairs(DEV) do
                    local lent = game.loadout:lent(row.kind)
                    Scribble.printBig(I18n.t(lent and row.on or row.off),
                        lay.cx, lay.hint + line * (i + 1), 1,
                        Palette.graphite, { seed = 52 + i })
                end
            end
        end
    end

    if lay.dev then self:drawSwitch(game, lay, progress) end
end

return Pause
