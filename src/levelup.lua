-- The draft.
--
-- Levelling up holds the run and lays three cards on the page, each with a
-- selection box under it, and you pick one exactly the way the title screen is
-- answered (src/scribble.lua): scribble in the box under the card you want. As
-- everywhere else the answer is armed while the pen is down and committed when
-- it comes off, so a scribble that carries on into the next box changes its
-- mind.
--
-- **The cards do not simply appear.** They slide on -- up off the bottom of the
-- page when they are laid across it, in past the left when they are stacked
-- down it -- and slide back off the same way once one has been answered, and
-- nothing on this screen reads the pen until they have landed (`arriving`). A
-- level lands in the middle of a fight, with a finger already on the page laying
-- tool strokes, and the fifth of a second the cards take to arrive is the fifth
-- of a second that finger has to notice the question. A pointer held down across
-- the slide is stale when it ends, so the first thing the draft ever reads is a
-- press that began after the cards were there to be pressed.
--
-- The same worry is why a card is no longer a target. Tapping one used to fill
-- its box for you; that meant one dab of a finger that was mid-stroke when the
-- level landed could spend a level, on a target a third of the page across. The
-- route is flagged off rather than deleted (`TAP_CARDS`) -- it is the right
-- gesture on a screen you arrive at deliberately -- and what is left is a box you
-- scribble in, which is what every other question in this game is.
--
-- The cards are the one thing in this game drawn on paper rather than in ink:
-- they are laid *on* the page, they cover the run frozen underneath, and the
-- three of them are the only thing you can do with the page while they are
-- there. Everything else about them is drawn -- a wonky border that warms up as
-- the box under it fills, and the scribble itself, sitting in the box the way
-- ink sits on paper. Ink that missed every box is not an answer, just ink, and
-- goes under the cards and fades.
--
-- Two cards are not paper. The first level of a tool line hands you the tool
-- itself and spends one of the four places on the strip, and it is sky; a fusion
-- does that *and* spends two finished lines doing it, and it is blush. See
-- `unlocks` and `fuses`.
--
-- What is *in* the cards is none of this file's business: it is handed a list
-- of upgrade lines (src/upgrades.lua) and hands back the id of the one that was
-- circled.
--
-- **And, for a run that has bought any, up to three buttons in the bottom corner**
-- (src/perks.lua -- the ones spent *here*, which is what `spent` on the row says;
-- a retake is spent the frame the run would have ended and has no button on this
-- screen). They are `Hud`'s own box -- the corner button's, drawn through
-- `Hud.drawButton` -- and they are **pressed rather than answered**, which on a
-- screen where everything else is a box you scribble in wants saying out loud:
-- pressing one does not answer the question, it changes what the question is.
-- REROLL asks again, SKIP withdraws it, and EXPEL turns the three boxes from three
-- ways of saying yes into three ways of saying never again -- which is still
-- answered by scribbling one of them, so the one part of this that cannot be taken
-- back is still taken the only way anything here is taken.
--
-- They sit in the corner **opposite the thumb stick** (`Hud.toolSide`), which is
-- the same ergonomic rule the tool column is placed by: one hand walks and the
-- other draws, and everything you press belongs to the thumb that is not on the
-- stick. There is no stick while a run is held, but a corner you have spent the
-- last ten minutes not putting your thumb in is still the corner to put a button
-- in.
--
-- A button with no uses left is drawn grey rather than dropped, because a row that
-- shrank as it was spent would move the buttons beside it; a *line* the run never
-- bought has no button at all, because these are things you have rather than
-- things the screen offers -- and so does a line the run cannot spend on a draft.

local Palette = require("src.palette")
local I18n = require("src.i18n")
local Font = require("src.font")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hud = require("src.hud")
local Upgrades = require("src.upgrades")
local Perks = require("src.perks")
local Sfx = require("src.sfx")
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

-- The cards arriving and leaving. Arriving is the guard the whole screen now
-- rests on -- a level lands mid-fight and this is the moment the hand has to see
-- it coming -- and it is CARD_TIME over again on purpose: a card finishes drawing
-- itself on at the instant it lands, so the two animations read as one. Leaving
-- is quicker, because by then the question has been answered and the flash has
-- already said so: the slide out is the run coming back, not part of the asking.
local SLIDE_IN = 0.22
local SLIDE_OUT = 0.14

-- Whether tapping a card fills its box for you -- see the note at the top of the
-- file. Off, and kept rather than cut: the gesture is right for a screen that is
-- not interrupting anything, and this one may one day not be.
local TAP_CARDS = false

-- The bought buttons in the bottom corner. The box is the tool selector's
-- (`Hud.SEL_SIZE`), since what stands in it is a tool-sized drawing; what belongs
-- here is only how they are spaced and how far off the edge of the page they sit.
local BTN_GAP = 4         -- one button to the next
local BTN_COUNT_GAP = 2   -- a button to the figure over it, which is the page
                          -- side of a box on the bottom edge -- the same rule the
                          -- margin columns write a level by (src/hud.lua)
local BTN_EDGE = 7        -- and the whole row off the corner of the page it is
                          -- allowed. Wider than the corner button's own margin on
                          -- purpose: that one is alone at the top of the page with
                          -- nothing to be crowded by, and this is three boxes of
                          -- thumb target sitting in the corner a thumb comes at
                          -- from outside the screen

function LevelUp.new()
    return setmetatable({ cards = {}, buttons = {}, perks = {} }, LevelUp)
end

-- `offer` is the upgrade lines to put on the cards, in order.
function LevelUp:open(game, offer)
    self.offer = offer
    self.t = 0
    -- arriving -> asking -> confirm -> leaving. The two slides are as much a part
    -- of the question as the flash between them: the first is the warning, and
    -- the last is the answer being carried off the page.
    self.phase = "arriving"
    self.slideT = 0
    self.chosen = nil
    self.confirmT = 0
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)
    self.wrapped = nil     -- the text, broken to the width the cards ended up
    self.wrappedLang = nil -- ... and the language it was broken in

    -- A pointer already down when the level landed -- a pen mid-stroke, which
    -- is the usual way to be levelling up -- is not this screen's to read at
    -- all: it draws nothing until it has been lifted and pressed afresh. It is
    -- taken again on every frame the cards are still arriving, so a finger that
    -- comes down *during* the slide is stale as well; what the draft reads is a
    -- press that began after the cards had landed, and nothing else.
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

    -- What the run bought (src/perks.lua), and whether one of them is armed. The
    -- table is the *run's* rather than a copy of it, so a use spent by Game shows
    -- on the button without anything being told -- which is what lets a reroll
    -- reopen this screen with one fewer of itself on it.
    self.perks = game.perks or {}
    self.expelling = false
    self.act = nil

    -- A button for every line the run is carrying that is *spent here*
    -- (`spent` on the row, src/perks.lua). The counter sells one thing that is
    -- not -- a retake, which is spent the frame the run would have ended -- and it
    -- has no button, because a button you can press that does nothing is worse
    -- than no button at all: it would read as a use this screen was refusing.
    self.buttons = {}
    for _, row in ipairs(Perks.list) do
        if row.spent == "draft" and self.perks[row.key] ~= nil then
            self.buttons[#self.buttons + 1] = { row = row, key = row.key }
        end
    end
end

-- How many uses of one are left. Nil for a line the run never bought, which is a
-- line with no button rather than a button with nothing in it.
function LevelUp:uses(key)
    return self.perks[key] or 0
end

-- Whether pressing one would do anything. A use left, and -- for EXPEL alone --
-- something to expel *and* something left over afterwards: throwing away the last
-- card on the table would be a draft with no way out of it, and a run may not be
-- left standing on one.
function LevelUp:usable(key)
    if self:uses(key) <= 0 then return false end
    if key == "expel" then return #self.cards > 1 end
    return true
end

--- layout --------------------------------------------------------------------

-- How far off the page the cards are, 0 while they are being read and 1 when
-- they are entirely gone. The whole of the animation is this one number; where
-- "off the page" is depends on which way the cards are laid out, and that is
-- `layout`'s to say.
--
-- Squared either way, and the two squares are deliberately the wrong way round
-- from one another. Arriving decelerates into place -- quick off the edge, the
-- last few pixels slowly -- so the cards read as laid down rather than fired at
-- you. Leaving accelerates, so they are already going by the time you notice
-- they went: a slide out that eased into a stop would hold the run still for a
-- tenth of a second on cards that had stopped meaning anything.
function LevelUp:away()
    if self.phase == "arriving" then
        local p = 1 - util.clamp(self.slideT / SLIDE_IN, 0, 1)
        return p * p
    elseif self.phase == "leaving" then
        local p = util.clamp(self.slideT / SLIDE_OUT, 0, 1)
        return p * p
    end
    return 0
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

    -- The bought buttons are placed here and the stack is *not* told about them.
    -- They were given a reserve at first and it was taken away again: a run that
    -- had been to the canteen read its cards a dozen pixels higher up the page
    -- than a run that had not, which made where the question sits depend on what
    -- was bought weeks ago. The cards are the question and they get the middle of
    -- the page in every run. What that costs is a corner: on a short screen with a
    -- long carry row the row of buttons is close under it, and the buttons win the
    -- corner because they are drawn last.
    self:layoutButtons(game)

    local lay = {}
    -- Counted off the cards on the table rather than off three: EXPEL replaces the
    -- card it threw out, and on a catalogue with nothing left to deal it leaves two
    -- (`Game:expelLine`). A row measured at three and drawn with two is a row
    -- centred on a width nothing on it has.
    local n = math.max(1, #self.cards)
    lay.side = usable >= CARD_MIN_W * n + GAP * (n - 1)
    lay.cardW = lay.side
        and math.floor((usable - GAP * (n - 1)) / n)
        or math.min(usable, CARD_MAX_W)

    -- The text is re-broken only when the width it has to fit actually changes,
    -- so a window being dragged is the only thing that ever pays for it.
    -- Cached on the width *and the language*: a card is dealt once and read for as
    -- long as the draft is up, and the language can be changed between one draft
    -- and the next. Where a line breaks is a property of the words that go on the
    -- page, and the catalogue holds English (src/i18n.lua).
    if self.wrapped ~= lay.cardW or self.wrappedLang ~= I18n.lang then
        self.wrapped = lay.cardW
        self.wrappedLang = I18n.lang
        self.lines = {}
        local most = 1
        for i, up in ipairs(self.offer) do
            self.lines[i] = Font.wrap(
                I18n.t(Upgrades.levelAt(up, self.levels[i]).text),
                lay.cardW - PAD * 2)
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
    local strip = lay.side and unit or unit * n + GAP * (n - 1)

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

    -- Where the cards are coming in from, or going out to. A row laid across the
    -- page comes up off the bottom edge and a column stacked down it comes in
    -- past the left, which is the short way in either shape: each slides along
    -- the axis it is thinnest on, so it is clear of the page in the fewest
    -- pixels and spends the whole slide moving rather than crawling. It is also,
    -- on a phone held either way round, the edge the cards are already nearest.
    --
    -- Whole pixels, like everything else that moves in this game: the offset is
    -- floored once here rather than per card, so the three of them travel as one
    -- sheet instead of stepping a pixel apart from each other on the way.
    local colX = left + math.floor((availW - lay.cardW) / 2)
    local away = self:away()
    local dx, dy = 0, 0
    if away > 0 then
        if lay.side then
            dy = math.floor(away * (game.vh - lay.cards))
        else
            dx = -math.floor(away * (colX + lay.cardW))
        end
    end

    for i, card in ipairs(self.cards) do
        if lay.side then
            card.x = left
                + math.floor((availW - (lay.cardW * n + GAP * (n - 1))) / 2)
                + (i - 1) * (lay.cardW + GAP)
            card.y = lay.cards
        else
            card.x = colX
            card.y = lay.cards + (i - 1) * (unit + GAP)
        end
        card.x, card.y = card.x + dx, card.y + dy
        card.w, card.h = lay.cardW, lay.cardH

        self.choice:place(card.box,
            card.x + math.floor((lay.cardW - card.box.w) / 2),
            card.y + lay.cardH + BOX_GAP)
    end

    self.lay = lay
    return lay
end

-- The row of bought buttons, in the bottom corner opposite the thumb stick.
--
-- The row reads *out of* its corner rather than always left to right, so the first
-- of them -- REROLL, the one a run reaches for most -- is the one nearest the
-- thumb whichever corner it is in. The figure over each says what is left, on the
-- page side of its own box, which on the bottom edge is up: that is the margin
-- columns' rule (src/hud.lua) applied to a row instead of a column.
function LevelUp:layoutButtons(game)
    if #self.buttons == 0 then return end

    local ins = game.inset
    local size = Hud.SEL_SIZE
    -- Off the experience bar rather than off the safe edge. The bar runs the
    -- whole width of the foot of the page, so the bottom of the safe area is not
    -- free page any more and a row measured from it stands on a readout -- and
    -- these are the widest touch targets in the game, so the finger reaching for
    -- one lands on the bar a good five pixels before the box does.
    local y = Hud.xpTop(game) - BTN_EDGE - size
    local rightwards = Hud.toolSide() == "left"
    local from = rightwards
        and ins.l + BTN_EDGE
        or game.vw - ins.r - BTN_EDGE - size

    for i, btn in ipairs(self.buttons) do
        local step = (i - 1) * (size + BTN_GAP)
        btn.x = rightwards and from + step or from - step
        btn.y = y
    end

    self.btnTop = y - BTN_COUNT_GAP - Font.height
end

-- A finger is bigger and blinder than a mouse, the same allowance every small
-- target in this game is given.
local function btnPad()
    return Input.usingTouch and 5 or 2
end

function LevelUp:perkAt(x, y)
    local pad = btnPad()
    local size = Hud.SEL_SIZE

    for _, btn in ipairs(self.buttons) do
        if btn.x and x >= btn.x - pad and x <= btn.x + size + pad
            and y >= btn.y - pad and y <= btn.y + size + pad then
            return btn
        end
    end
end

--- update --------------------------------------------------------------------

-- `act` is what the answered box means, and it is latched here rather than read
-- off `self.expelling` when the flash finishes: EXPEL is armed while you scribble
-- and the button is still pressable, so what the box was answered *as* has to be
-- decided at the moment it was answered.
function LevelUp:commit(box)
    self.phase = "confirm"
    Sfx.play("accept")
    self.chosen = box
    self.act = self.expelling and "expel" or "take"
    self.confirmT = 0
end

-- The cards off the page, and only then is Game told. Whatever was drawn in the
-- answered box goes with them, since the box travels with the card it belongs to
-- (`Choice:place` moves a box's ink along with it) -- the answer leaves on the
-- card it answered, which is the point of carrying it off rather than cutting.
--
-- Nothing here can be taken back: `act` is already latched, and the slide is only
-- how long it takes to look like it happened.
function LevelUp:leave()
    self.phase = "leaving"
    self.slideT = 0
end

-- Ink that lands in a box is the answer and is counted there; ink that misses
-- is just ink on the page.
function LevelUp:mark(x, y, quiet)
    -- Except over a button, which swallows what crosses it rather than being drawn
    -- on -- the HUD-furniture rule every screen in this game is held to. A
    -- swallowed stamp was never a line, so returning false is also what keeps the
    -- pen from swishing at it (src/scribble.lua).
    if self:perkAt(x, y) then return false end

    -- Either way it is ink -- in a box it is the answer, off one it is a line on
    -- the page -- so either way the pen is drawing and sounds it.
    if self.choice:mark(x, y, quiet) then return true end
    self.marks:add(x, y)
    return true
end

-- The press edge. A button, which is furniture: it lies over the page and is
-- pressed rather than answered.
--
-- And, behind `TAP_CARDS`, a card. The tap drew the scribble into the card's box
-- rather than jumping past it, exactly as the keyboard does, so a tapped card was
-- still answered the only way anything here is answered -- but a card is a third
-- of the page across, and a finger that was mid-stroke when the level landed
-- could spend a level on one by accident. Off, and the flag is the note saying
-- what would come back if the draft ever stopped interrupting a fight.
function LevelUp:tap(x, y)
    local btn = self:perkAt(x, y)
    if btn then
        self:pressPerk(btn.key)
        return
    end

    if not TAP_CARDS then return end

    for _, card in ipairs(self.cards) do
        if x >= card.x and x < card.x + card.w
            and y >= card.y and y < card.y + card.h then
            self.choice:autoFill(card.box)
            return
        end
    end
end

-- One of the three, pressed. Two of them are whole moves and are handed straight
-- back to Game on this frame; the third has no target yet, so all it does is turn
-- the boxes into refusals -- and pressing it again puts them back, since a mode
-- you cannot leave is a mode you can be trapped in.
--
-- Nothing is spent here. Whose coins and whose uses these are is Game's
-- (`Game:rerollDraft` and the two beside it), which is what keeps this file
-- ignorant of what any of it costs -- exactly as it is ignorant of what any card
-- does.
function LevelUp:pressPerk(key)
    if self.phase ~= "asking" or not self:usable(key) then return end

    if key == "expel" then
        self.expelling = not self.expelling
        Sfx.play("transition2")
        return
    end

    Sfx.play("transition")
    self.act = key
end

-- What the screen was answered with, and the id it was answered about. Four
-- answers, and the pair is what keeps Game from having to guess: `"take"` and
-- `"expel"` both name a line, while `"reroll"` and `"skip"` name nothing. All
-- four arrive at the same moment -- once the cards are off the page -- so Game
-- never resumes a run under a draft that is still on it. Nothing at all until
-- then.
function LevelUp:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    -- On their way off, and then the word Game has been waiting for. The flash on
    -- the answered box goes on running the whole way out: it is the answer, and an
    -- answer that froze on whichever half of the flash it happened to be on would
    -- leave the page as a card that was either lit or not for no reason.
    if self.phase == "leaving" then
        self.slideT = self.slideT + dt
        self.confirmT = self.confirmT + dt
        if self.slideT >= SLIDE_OUT then
            return self.act, self.chosen and self.chosen.key
        end
        return
    end

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then self:leave() end
        return
    end

    -- On their way on, and nothing at all is readable yet: not the pen below, and
    -- not the buttons either -- `pressPerk` and `keypressed` both refuse any phase
    -- but "asking". The stale press is re-taken every frame, so a finger that
    -- comes down mid-slide has to be lifted like one that was already down.
    if self.phase == "arriving" then
        self.slideT = self.slideT + dt
        self.stale = Input.pointerDown
        if self.slideT < SLIDE_IN then return end
        self.phase = "asking"
    end

    -- A button pressed by the keyboard between one frame and the next, which is
    -- the one route into this that does not go through the pen below.
    if self.act then
        self:leave()
        return
    end

    -- The keyboard draws the scribble rather than jumping past it (and so does a
    -- tap on a card, where `TAP_CARDS` allows one), and there is no pen to lift,
    -- so that answer stands as soon as the box fills.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    -- The press that was already down when the screen opened -- or that came down
    -- while the cards were still arriving -- stays invisible until it is lifted;
    -- only a press made at cards that had landed draws here.
    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(px, py) self:tap(px, py) end)

    -- REROLL or SKIP, pressed on the edge the pen just reported. There is no box
    -- to flash, so the cards start leaving on the frame the button went down and
    -- the word goes back when they are clear -- which is what makes a reroll read
    -- as one deal of cards replacing another rather than as three cards changing
    -- what they say. EXPEL never lands here: all it did was change what a box
    -- means, and a box still has to be scribbled.
    if self.act then
        self:leave()
        return
    end

    -- Armed, not answered: nothing is picked until the pen comes off the page.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
    end
end

-- The numbers answer a card and three letters press a button, mnemonic and
-- advertised nowhere -- the timetable's own arrangement for the three tabs in its
-- margin, and for the same reason: the buttons are on the page to be pressed and a
-- hint line naming three keys is a paragraph of instructions on a screen that has
-- one line to spare.
local PERK_KEY = { r = "reroll", s = "skip", e = "expel" }

function LevelUp:keypressed(key)
    if self.phase ~= "asking" then return end

    local perk = PERK_KEY[key]
    if perk then
        self:pressPerk(perk)
        return
    end

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
    -- Armed to expel, the question on the page is a different question, so the one
    -- line under the cards says the different one. It is the only account the
    -- player gets of why scribbling a box is about to do the opposite of what it
    -- did last time, and it is worth the whole line.
    if self.expelling then return "SCRIBBLE THE LINE TO THROW OUT" end
    -- Which of these is true is `TAP_CARDS`'s to say, so the line and the gesture
    -- cannot drift apart: a hint that offers a tap the screen has stopped taking
    -- is worse than no hint at all.
    if TAP_CARDS then return "TAP A CARD OR SCRIBBLE ITS BOX" end
    return "SCRIBBLE THE BOX UNDER A CARD"
end

-- Whether this card hands you a tool rather than improving something.
--
-- It is the one pick in the draft that costs a run something it does not get
-- back: a tool line's first level puts the tool on the strip, and the strip has
-- four places on it (`Loadout.SLOTS`) one of which is gone before the run
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

-- And whether it is a *fusion* (`needs` and `fuses` in src/upgrades.lua), which
-- is the same argument one step further on. A tool unlock is a run being decided;
-- a fusion is a run being decided *and* two lines it already finished being spent
-- on it, and it is the only card in the draft that can turn up once in a run and
-- never again. So it gets the third colour, and the reason it gets a colour
-- rather than a word is the reason the sky card does: three cards go down and you
-- have to know which one you are choosing about before you have read a line.
local function fuses(up, level)
    return level == 1 and up.fuses ~= nil
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
    -- Sky rather than blush for the unlock, which is the other light fill in the
    -- palette: the border warms slate -> blue -> red as the box fills, and blush
    -- costs the red -- the step that says the answer has landed -- where sky only
    -- costs the blue halfway step, which is the one you never stop on.
    --
    -- Which is exactly why blush is what is left for the fusion, and why spending
    -- it there is the right way round rather than a hole in that rule. There are
    -- two light fills and there is now a third card to tell apart, so one of them
    -- has to pay the border; the one to pay it is the card a run sees once, on a
    -- draft it has spent ten levels arriving at, where what the colour is saying
    -- is worth more than the warm step it costs -- and the confirm flash is red
    -- against *ink* rather than against the fill, so the answer landing still
    -- reads on it. An unlock turns up in every run and several times over.
    local fill = Palette.paper
    if fuses(up, level) then
        fill = Palette.blush
    elseif unlocks(up, level) then
        fill = Palette.sky
    end
    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", card.x, card.y, card.w, card.h)

    Scribble.drawBox(card, util.clamp(self.t / CARD_TIME, 0, 1), color, 20 + i * 3, 0)

    -- Through Hud rather than straight off the sprite, so a fused line's drawing
    -- carries the blush plate here as well (`Hud.drawIcon`). On the card that
    -- *is* the fusion it lands on blush and so cannot be seen, which is right --
    -- the whole card is already saying it. Where it shows is the second, third
    -- and fourth levels of a fused line, on the ordinary paper card every other
    -- level is dealt on: the plate is what those have in common with the card
    -- ten levels back that started it.
    Hud.drawIcon(up.icon, card.x + PAD + ICON / 2, card.y + PAD + ICON / 2)

    local textX = card.x + PAD + ICON + 2
    love.graphics.setColor(Palette.ink)
    Font.print(I18n.t(up.name), textX, card.y + PAD)

    -- A line you have never taken says so, because the first level of one is
    -- the only pick that changes what the run *is* rather than what it is like.
    local text = level == 1 and I18n.t("NEW") or I18n.t("LV %d"):format(level)
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
    -- tool has nothing after it *before* you spend one of four permanent slots
    -- reaching it.
    --
    -- An endless line answers this with infinity and so never says MAX, which is
    -- exactly right and costs nothing to arrange: there is no level of one that
    -- is its last, and the climbing LV is the only thing it has to say.
    if level == Upgrades.levelsIn(up) then
        love.graphics.setColor(Palette.red)
        Font.print(I18n.t("MAX"), textX + Font.width(text .. " "), card.y + PAD + 6)
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

-- The row of bought buttons, out past the overprint pass with the rest of the HUD
-- because that is what they are: boxes filled in paper, and paper does not survive
-- being paired with the ruling under it -- a border landing on a rule comes out a
-- step darker and the box reads as a hole cut in the page.
--
-- Red on one of them means armed, which in this game's furniture it always does,
-- and only EXPEL can be: the other two are gone the frame they are pressed, so
-- there is no moment at which either could be drawn hot.
function LevelUp:drawButtons()
    for _, btn in ipairs(self.buttons) do
        if btn.x then
            local left = self:uses(btn.key)
            local spent = not self:usable(btn.key)

            Hud.drawButton(btn.x, btn.y, Hud.SEL_SIZE, btn.row.icon,
                btn.key == "expel" and self.expelling, spent)

            love.graphics.setColor(spent and Palette.graphite or Palette.slate)
            Font.printCentered(("%d"):format(left),
                btn.x + Hud.SEL_SIZE / 2, self.btnTop)
        end
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

    Scribble.printBig(I18n.t("LEVEL %d"):format(game.player.level),
        lay.cx, lay.head, HEAD_SCALE,
        Palette.red, { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    for i, card in ipairs(self.cards) do
        self:drawCard(i, card)
    end

    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        -- Red for armed, which is what red on the furniture means -- and armed to
        -- throw a line out is armed too, so the line that says so is in the same
        -- colour as the line that says a box is full.
        Scribble.printBig(I18n.t(self:prompt()), lay.cx, lay.hint, 1,
            (armed or self.expelling) and Palette.red or Palette.slate,
            { seed = 61 })
        if not Input.usingTouch and not armed then
            Scribble.printBig(I18n.t("OR PRESS 1 2 3"), lay.cx,
                lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 62 })
        end
    end

    self:drawButtons()
end

return LevelUp
