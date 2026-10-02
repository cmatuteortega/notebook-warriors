-- The game over card: the same object as the win screen, paper laid on a frozen
-- run, drawable everywhere -- ink that misses the boxes just fades off. RETRY
-- builds the next run on the same lesson with the same hero (`Game:reset`),
-- QUIT hands the page back to the title screen. The mark (src/mark.lua) was
-- written for this card: a run that ends is a page handed in.

local Palette = require("src.palette")
local I18n = require("src.i18n")
local Font = require("src.font")
local Input = require("src.input")
local Mark = require("src.mark")
local Purse = require("src.purse")
local Scribble = require("src.scribble")
local Sfx = require("src.sfx")
local util = require("src.util")

local Over = {}
Over.__index = Over

local HEAD, TITLE = "CLASS DISMISSED", "GAME OVER"

-- Hoisted so the card is as wide as the widest thing it can ever hold rather
-- than as wide as what is on it now: it must not twitch wider when a box arms.
local ASK = "SCRIBBLE IN A BOX"
local LIFT, RELEASE = "LIFT TO CONFIRM", "RELEASE TO CONFIRM"
local KEYS = "OR PRESS 1 OR 2"

local LABEL_SCALE = 2
local BOX_TIME = 0.25  -- the card and the boxes drawing themselves on
local CONFIRM = 0.32   -- the answered box flashing before the answer takes hold
local CARD_PAD_X, CARD_PAD_Y = 8, 7

function Over.new()
    local self = setmetatable({}, Over)
    self:open(0, 0, 0)
    return self
end

-- Which class the run was sat as (src/course.lua), the same slate line on both
-- end cards. Printed at high school too, or the plain run reads as the one with
-- something missing and a player is never shown that the ladder exists.
function Over:courseLine()
    return I18n.t("SAT AT %s"):format(I18n.t(self.course))
end

-- The score is copied in rather than read off the run each frame: RETRY
-- replaces the run underneath, and this reports the run that ended.
function Over:open(time, kills, coins, course)
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    self.time, self.kills = time, kills
    -- The name rather than the row: a card prints it and asks it nothing.
    self.course = course or "HIGH SCHOOL"
    -- What the run was paid (src/purse.lua), already banked and worked out by
    -- the time this card is up: a card must not be a second opinion about it.
    self.coins = coins or 0
    -- Worked out once here: a grade reads the same on either page of the book.
    self.grade = Mark.forRun(time, false)

    -- A pointer already down when you died (a pen mid-stroke) is not a press.
    self.pen = Scribble.newPen(Input.pointerDown)

    self.choice = Scribble.newChoice({
        { key = "retry", label = "RETRY" },
        { key = "quit", label = "QUIT" },
    }, LABEL_SCALE)
end

function Over:score()
    return I18n.t("%s   %d KILLS"):format(
        ("%d:%02d"):format(math.floor(self.time / 60), math.floor(self.time % 60)),
        self.kills)
end

-- With the plus on it: the one fact here about the next run rather than this one.
function Over:coinLine()
    return ("+%d"):format(self.coins)
end

function Over:prompt()
    if self.choice.armed then
        return Input.usingTouch and LIFT or RELEASE
    end
    return ASK
end

-- The score is measured live (the run is over), but the mark is measured at the
-- widest grade in the ladder: the card must not be wider for a good run.
function Over:contentWidth()
    return math.max(
        Font.width(I18n.t(HEAD)),
        Font.width(I18n.t(TITLE)) * LABEL_SCALE,
        Mark.widest(),
        Font.width(self:score()),
        Font.width(self:courseLine()),
        Purse.width(self:coinLine()),
        self.choice:stripWidth(),
        Font.width(I18n.t(ASK)), Font.width(I18n.t(LIFT)),
        Font.width(I18n.t(RELEASE)), Font.width(I18n.t(KEYS)))
end

function Over:layout(game)
    local ins = game.inset
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    local lay, y = {}, CARD_PAD_Y
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 5
    lay.mark = y;  y = y + Mark.height() + 4
    lay.score = y; y = y + Font.height + 2
    lay.course = y; y = y + Font.height + 4
    lay.coins = y; y = y + Purse.height() + 8
    lay.boxes = y; y = y + Scribble.BOX_H + 9
    lay.hint = y;  y = y + hintH
    lay.cardH = y + CARD_PAD_Y

    local top = math.floor(ins.t + (game.vh - ins.t - ins.b - lay.cardH) / 2)
    lay.cardY = top
    lay.head = lay.head + top
    lay.title = lay.title + top
    lay.mark = lay.mark + top
    lay.score = lay.score + top
    lay.course = lay.course + top
    lay.coins = lay.coins + top
    lay.boxes = lay.boxes + top
    lay.hint = lay.hint + top

    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.labelY = lay.boxes + math.floor((Scribble.BOX_H - Font.height * LABEL_SCALE) / 2)

    lay.cardW = self:contentWidth() + CARD_PAD_X * 2
    lay.cardX = math.floor(lay.cx - lay.cardW / 2)

    self.choice:layout(lay.cx, lay.boxes)

    self.lay = lay
    return lay
end

function Over:commit(box)
    self.phase = "confirm"
    Sfx.play("accept")
    self.chosen = box
    self.confirmT = 0
end

function Over:mark(x, y, quiet)
    -- In a box or off one, it is ink either way and the pen sounds it.
    if self.choice:mark(x, y, quiet) then return true end
    self.marks:add(x, y)
    return true
end

--- update --------------------------------------------------------------------

-- Returns "retry" or "quit" on the frame the answer lands, nothing until then.
function Over:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then
            return self.chosen.key
        end
        return
    end

    -- The keyboard fills a box in rather than jumping past it, and there is no
    -- pen to lift, so the answer stands as soon as the scribble lands.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    local down = Input.pointerDown
    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end)

    -- Armed, not answered: a line carried on into the other box changes it.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
    end
end

function Over:keypressed(key)
    if self.phase ~= "asking" then return end

    if key == "1" then
        self.choice:autoFill(self.choice.boxes[1])
    elseif key == "2" then
        self.choice:autoFill(self.choice.boxes[2])
    end
end

--- draw ----------------------------------------------------------------------

function Over:draw(game)
    local lay = self:layout(game)

    self.marks:draw(0)

    local progress = util.clamp(self.t / BOX_TIME, 0, 1)

    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", lay.cardX, lay.cardY, lay.cardW, lay.cardH)
    Scribble.drawBox(
        { x = lay.cardX, y = lay.cardY, w = lay.cardW, h = lay.cardH },
        progress, Palette.slate, 7, 0)

    love.graphics.setColor(Palette.slate)
    Font.printCentered(I18n.t(HEAD), lay.cx, lay.head)

    -- Ink and still where the win card's title is blue and pulses: the colour on
    -- this card is spent on the mark, which is the thing that is news.
    Scribble.printBig(I18n.t(TITLE), lay.cx, lay.title, LABEL_SCALE, Palette.ink,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 7 })

    Mark.draw(self.grade, lay.cx, lay.mark)

    love.graphics.setColor(Palette.ink)
    Font.printCentered(self:score(), lay.cx, lay.score)

    love.graphics.setColor(Palette.slate)
    Font.printCentered(self:courseLine(), lay.cx, lay.course)

    -- Under the clock and body count since it is worked out from them, and in
    -- ink like them: a number the run kept, not the red thing about how it went.
    Purse.draw(self:coinLine(), lay.cx, lay.coins, Palette.ink)

    for i, box in ipairs(self.choice.boxes) do
        local color = Scribble.boxColor(box, self.chosen, self.confirmT)

        Scribble.printBig(Scribble.label(box), box.labelCx, lay.labelY,
            LABEL_SCALE, color,
            { shadow = Palette.paper, wobble = true, t = self.t, seed = 30 + i * 5 })
        Scribble.drawBox(box, progress, color, 10 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
    end

    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(I18n.t(self:prompt()), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 51 })
        if not Input.usingTouch and not armed then
            Scribble.printBig(I18n.t(KEYS), lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 52 })
        end
    end
end

return Over
