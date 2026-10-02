-- The retake card: the death card with no answer at all -- the only card in the
-- game that asks nothing, because a card offering to spend a life you already
-- bought is a question with one sensible answer. It runs on a clock instead
-- (`HOLD`), and nothing reaches it: no pen, no marks, no keys, hence the only
-- card here with no `Scribble.newPen` and no `Scribble.newMarks`.
--
-- The grace `Player:revive` hands over does not start running until the card
-- lifts (the player is only stepped while the state is `playing`), so the beat
-- spent reading this is not a beat spent spending it. The title is ink and
-- still like GAME OVER's, never the win card's blue: this is not a win. The
-- colour is spent on the count, which is the only news on the page.

local Palette = require("src.palette")
local I18n = require("src.i18n")
local Font = require("src.font")
local Scribble = require("src.scribble")
local util = require("src.util")

local Retake = {}
Retake.__index = Retake

local HEAD, TITLE = "ANOTHER CHANCE", "RETAKING"

-- A count rather than a sentence: the page must not promise a run not yet played.
local LEFT = "%d/%d CHARGES LEFT"

local LABEL_SCALE = 2
local BOX_TIME = 0.25  -- the card drawing itself on, the other two cards' own
local CARD_PAD_X, CARD_PAD_Y = 8, 7

-- The whole interruption, measured from the frame it opened rather than from the
-- frame it finished drawing on, so there is one number to argue about. Long
-- enough to read eight letters and a count, short because the horde that killed
-- you is frozen on the page behind it.
local HOLD = 1.5

function Retake.new()
    local self = setmetatable({}, Retake)
    self:open(0, 0)
    return self
end

-- Copied in rather than read off the run, and kept as numbers so the words are
-- built in the current language at the draw. `left` is the run's and `owned` is
-- the book's, and the book may grow between them (buy a level at the counter,
-- then CONTINUE a run that was dealt one), so the denominator is never let
-- below the numerator: `1/0` is the one thing this line must not say.
function Retake:open(left, owned)
    self.t = 0
    self.left = math.max(0, left)
    self.owned = math.max(owned, self.left)
end

--- layout --------------------------------------------------------------------

-- At the widest thing it could ever hold, which for the count means two figures:
-- a card whose width said which retake you were on would say it before you read.
function Retake:contentWidth()
    return math.max(
        Font.width(I18n.t(HEAD)),
        Font.width(I18n.t(TITLE)) * LABEL_SCALE,
        Font.width(I18n.t(LEFT):format(0, 0)))
end

function Retake:layout(game)
    local ins = game.inset

    local lay, y = {}, CARD_PAD_Y
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 6
    lay.left = y;  y = y + Font.height
    lay.cardH = y + CARD_PAD_Y

    local top = math.floor(ins.t + (game.vh - ins.t - ins.b - lay.cardH) / 2)
    lay.cardY = top
    lay.head = lay.head + top
    lay.title = lay.title + top
    lay.left = lay.left + top

    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.cardW = self:contentWidth() + CARD_PAD_X * 2
    lay.cardX = math.floor(lay.cx - lay.cardW / 2)

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

-- Returns "done" once the card has been up long enough, nothing until then.
function Retake:update(dt)
    self.t = self.t + dt
    if self.t >= HOLD then return "done" end
end

--- draw ----------------------------------------------------------------------

function Retake:draw(game)
    local lay = self:layout(game)

    local progress = util.clamp(self.t / BOX_TIME, 0, 1)

    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", lay.cardX, lay.cardY, lay.cardW, lay.cardH)
    Scribble.drawBox(
        { x = lay.cardX, y = lay.cardY, w = lay.cardW, h = lay.cardH },
        progress, Palette.slate, 7, 0)

    love.graphics.setColor(Palette.slate)
    Font.printCentered(I18n.t(HEAD), lay.cx, lay.head)

    Scribble.printBig(I18n.t(TITLE), lay.cx, lay.title, LABEL_SCALE, Palette.ink,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 7 })

    -- Red on the last one, the slot counters' and the canteen's own rule: red
    -- means there is no more of this.
    Scribble.printBig(I18n.t(LEFT):format(self.left, self.owned),
        lay.cx, lay.left, 1,
        self.left > 0 and Palette.slate or Palette.red, { seed = 51 })
end

return Retake
