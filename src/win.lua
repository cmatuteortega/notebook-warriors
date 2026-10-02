-- The win screen: the pause card's paper with a different question. END hands
-- the page back to the title screen with the score kept; ENDLESS gives the
-- horde back for another ten minutes, tougher, with another eye at the end
-- (`Spawner:nextCycle`). Outside the card is still page: drawable, and ink that
-- misses the boxes is just ink.

local Palette = require("src.palette")
local I18n = require("src.i18n")
local Font = require("src.font")
local Input = require("src.input")
local Mark = require("src.mark")
local Purse = require("src.purse")
local Scribble = require("src.scribble")
local Sfx = require("src.sfx")
local util = require("src.util")

local Win = {}
Win.__index = Win

local HEAD, TITLE = "THE EYE IS SHUT", "YOU WIN"

-- Hoisted so the card is as wide as the widest thing it can ever hold rather
-- than as wide as what is on it now: it must not twitch wider when a box arms.
local ASK = "SCRIBBLE IN A BOX"
local LIFT, RELEASE = "LIFT TO CONFIRM", "RELEASE TO CONFIRM"
local KEYS = "OR PRESS 1 OR 2"

local LABEL_SCALE = 2
local BOX_TIME = 0.25  -- the card and the boxes drawing themselves on
local CONFIRM = 0.32   -- the answered box flashing before the answer takes hold
local CARD_PAD_X, CARD_PAD_Y = 8, 7

function Win.new()
    local self = setmetatable({}, Win)
    self:open(0, 0, 1, 0)
    return self
end

-- The score is copied in rather than read off the run each frame: ENDLESS lets
-- the run go again underneath, and this reports the moment the eye went down.
function Win:open(time, kills, cycle, coins, course)
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- Kept as numbers and put into words at the draw: a string built at `open`
    -- would be built in whatever language `open` happened to run in.
    self.time, self.kills, self.cycle = time, kills, cycle
    -- The class it was sat as (src/course.lua), as a name rather than a row.
    -- `Over:courseLine` has why it is on both cards and printed at high school.
    self.course = course or "HIGH SCHOOL"
    -- What the run is WORTH so far (src/purse.lua) -- unlike the death card's,
    -- this has not been paid yet. END collects it, ENDLESS bets it grows.
    self.coins = coins or 0
    -- The eye is worth the top of the ladder outright rather than by the clock
    -- (src/mark.lua); a letter is not a word, so nothing here to translate.
    self.grade = Mark.forRun(time, true)

    -- A pointer already down when the eye died (a pen mid-stroke) is not a press.
    self.pen = Scribble.newPen(Input.pointerDown)

    self.choice = Scribble.newChoice({
        { key = "end", label = "END" },
        { key = "endless", label = "ENDLESS" },
    }, LABEL_SCALE)
end

-- The clock and the body count; the eye tally is a separate line (`tallyLine`).
function Win:score()
    return I18n.t("%s   %d KILLS"):format(
        ("%d:%02d"):format(math.floor(self.time / 60), math.floor(self.time % 60)),
        self.kills)
end

-- With the plus on it, exactly as the death card writes it: the same fact.
function Win:coinLine()
    return ("+%d"):format(self.coins)
end

function Win:courseLine()
    return I18n.t("SAT AT %s"):format(I18n.t(self.course))
end

function Win:tallyLine()
    if self.cycle <= 1 then return nil end
    return I18n.t("EYE %d DOWN"):format(self.cycle)
end

function Win:prompt()
    if self.choice.armed then
        return Input.usingTouch and LIFT or RELEASE
    end
    return ASK
end

-- The score lines are measured live rather than at their widest, unlike the
-- hints: the run is frozen while this card is up.
function Win:contentWidth()
    local tally = self:tallyLine()
    return math.max(
        Font.width(I18n.t(HEAD)),
        Font.width(I18n.t(TITLE)) * LABEL_SCALE,
        -- At the widest grade in the ladder, so the two cards a mark can appear
        -- on come out the same width.
        Mark.widest(),
        Font.width(self:score()),
        Font.width(self:courseLine()),
        tally and Font.width(tally) or 0,
        Purse.width(self:coinLine()),
        self.choice:stripWidth(),
        Font.width(I18n.t(ASK)), Font.width(I18n.t(LIFT)),
        Font.width(I18n.t(RELEASE)), Font.width(I18n.t(KEYS)))
end

function Win:layout(game)
    local ins = game.inset
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    local lay, y = {}, CARD_PAD_Y
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 5
    lay.mark = y;  y = y + Mark.height() + 4
    -- Asked once and used for both the room and the row.
    local tally = self:tallyLine()
    -- The course line always, the eye tally only past the first eye.
    lay.score = y; y = y + Font.height + 2
    lay.course = y; y = y + Font.height + (tally and 2 or 0)
    if tally then
        lay.tally = y
        y = y + Font.height
    end
    y = y + 4
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
    if lay.tally then lay.tally = lay.tally + top end
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

function Win:commit(box)
    self.phase = "confirm"
    Sfx.play("accept")
    self.chosen = box
    self.confirmT = 0
end

function Win:mark(x, y, quiet)
    -- In a box or off one, it is ink either way and the pen sounds it.
    if self.choice:mark(x, y, quiet) then return true end
    self.marks:add(x, y)
    return true
end

--- update --------------------------------------------------------------------

-- Returns "end" or "endless" on the frame the answer lands, nothing until then.
function Win:update(dt, game)
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

function Win:keypressed(key)
    if self.phase ~= "asking" then return end

    if key == "1" then
        self.choice:autoFill(self.choice.boxes[1])
    elseif key == "2" then
        self.choice:autoFill(self.choice.boxes[2])
    end
end

--- draw ----------------------------------------------------------------------

function Win:draw(game)
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

    -- The only blue lettering in the game: red has been hitting you for ten
    -- minutes and ink asks every other question, so the one line that has never
    -- appeared before gets a colour never used for words.
    local pulse = math.sin(self.t * 3.4) > 0
    Scribble.printBig(I18n.t(TITLE), lay.cx, lay.title, LABEL_SCALE,
        pulse and Palette.blue or Palette.slate,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 7 })

    Mark.draw(self.grade, lay.cx, lay.mark)

    love.graphics.setColor(Palette.ink)
    Font.printCentered(self:score(), lay.cx, lay.score)

    love.graphics.setColor(Palette.slate)
    Font.printCentered(self:courseLine(), lay.cx, lay.course)
    if lay.tally then
        Font.printCentered(self:tallyLine(), lay.cx, lay.tally)
    end

    -- Under the numbers it is worked out from and in ink like them: the colour
    -- on this card is spent on the title and the mark.
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

return Win
