-- The win screen: the one card in the game that is handed to you rather than
-- taken from you.
--
-- It is the pause screen's card with a different question on it, and that is
-- on purpose -- a run that has just killed the eye is looking at a page in the
-- same state a paused one is, so the answer is the same one: paper, which is
-- the only colour that covers what is under it, with the frozen run showing
-- round the edges of it.
--
-- The question is what to do with the win. END hands the page back to the title
-- screen and the run is over with the score on it. ENDLESS gives the horde back
-- and starts another ten minutes, tougher, with another eye at the end of it
-- (`Spawner:nextCycle`) -- so the card is a real choice rather than a
-- congratulation with a button under it: a run you end is a run you keep, and a
-- run you carry on is one you are betting.
--
-- Everything outside the card is still page, exactly as on the pause screen:
-- the whole of it stays drawable and ink that misses the boxes is just ink.

local Palette = require("src.palette")
local Font = require("src.font")
local Input = require("src.input")
local Scribble = require("src.scribble")
local util = require("src.util")

local Win = {}
Win.__index = Win

local HEAD, TITLE = "THE EYE IS SHUT", "YOU WIN"

-- Hoisted for the same reason the pause card's are: the card is as wide as the
-- widest thing it can ever hold rather than as wide as what is on it now, so it
-- does not twitch a few pixels wider the moment a box arms.
local ASK = "SCRIBBLE IN A BOX"
local LIFT, RELEASE = "LIFT TO CONFIRM", "RELEASE TO CONFIRM"
local KEYS = "OR PRESS 1 OR 2"

local LABEL_SCALE = 2
local BOX_TIME = 0.25  -- the card and the boxes drawing themselves on
local CONFIRM = 0.32   -- the answered box flashing before the answer takes hold
local CARD_PAD_X, CARD_PAD_Y = 8, 7

function Win.new()
    local self = setmetatable({}, Win)
    self:open(0, 0, 1)
    return self
end

-- The score is copied in on the way up rather than read off the run every
-- frame, because ENDLESS lets the run go again underneath this card: what the
-- screen is reporting is the moment the eye went down, not whatever the run has
-- got to since.
function Win:open(time, kills, cycle)
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    self.score = ("%d:%02d   %d KILLS"):format(
        math.floor(time / 60), math.floor(time % 60), kills)
    -- Only once there is more than one to count. The first win is "the eye";
    -- the fourth is worth saying out loud.
    self.tally = cycle > 1 and ("EYE " .. cycle .. " DOWN") or nil

    -- A pointer already down when the eye died -- a pen mid-stroke, most likely,
    -- since something of yours was hitting it -- is not a press of this screen.
    self.pen = Scribble.newPen(Input.pointerDown)

    self.choice = Scribble.newChoice({
        { key = "end", label = "END" },
        { key = "endless", label = "ENDLESS" },
    }, LABEL_SCALE)
end

function Win:prompt()
    if self.choice.armed then
        return Input.usingTouch and LIFT or RELEASE
    end
    return ASK
end

-- The score lines are measured live rather than at their widest, unlike the
-- hints: the run is frozen while this card is up, so neither of them can change
-- under it.
function Win:contentWidth()
    return math.max(
        Font.width(HEAD),
        Font.width(TITLE) * LABEL_SCALE,
        Font.width(self.score),
        self.tally and Font.width(self.tally) or 0,
        self.choice:stripWidth(),
        Font.width(ASK), Font.width(LIFT), Font.width(RELEASE), Font.width(KEYS))
end

function Win:layout(game)
    local ins = game.inset
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    local lay, y = {}, CARD_PAD_Y
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 6
    lay.score = y; y = y + Font.height + (self.tally and 2 or 0)
    if self.tally then
        lay.tally = y
        y = y + Font.height
    end
    y = y + 8
    lay.boxes = y; y = y + Scribble.BOX_H + 9
    lay.hint = y;  y = y + hintH
    lay.cardH = y + CARD_PAD_Y

    local top = math.floor(ins.t + (game.vh - ins.t - ins.b - lay.cardH) / 2)
    lay.cardY = top
    lay.head = lay.head + top
    lay.title = lay.title + top
    lay.score = lay.score + top
    if lay.tally then lay.tally = lay.tally + top end
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
    self.chosen = box
    self.confirmT = 0
end

function Win:mark(x, y, quiet)
    if self.choice:mark(x, y, quiet) then return end
    self.marks:add(x, y)
end

--- update --------------------------------------------------------------------

-- Returns "end" or "endless" on the frame the answer lands, and nothing at all
-- until then.
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
    -- pen to lift, so that answer stands as soon as the scribble lands.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    local down = Input.pointerDown
    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end)

    -- Armed, not answered: a line that carries on into the other box changes
    -- the answer rather than being too late.
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
    Font.printCentered(HEAD, lay.cx, lay.head)

    -- Blue rather than the pause card's ink, and it is the only lettering in the
    -- game that is: red is what has been hitting you for ten minutes and ink is
    -- what every other question is asked in, so the one line that has never
    -- appeared before gets a colour that has never been used for words.
    local pulse = math.sin(self.t * 3.4) > 0
    Scribble.printBig(TITLE, lay.cx, lay.title, LABEL_SCALE,
        pulse and Palette.blue or Palette.slate,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 7 })

    love.graphics.setColor(Palette.ink)
    Font.printCentered(self.score, lay.cx, lay.score)
    if lay.tally then
        love.graphics.setColor(Palette.slate)
        Font.printCentered(self.tally, lay.cx, lay.tally)
    end

    for i, box in ipairs(self.choice.boxes) do
        local color = Scribble.boxColor(box, self.chosen, self.confirmT)

        Scribble.printBig(box.label, box.labelCx, lay.labelY, LABEL_SCALE, color,
            { shadow = Palette.paper, wobble = true, t = self.t, seed = 30 + i * 5 })
        Scribble.drawBox(box, progress, color, 10 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
    end

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

return Win
