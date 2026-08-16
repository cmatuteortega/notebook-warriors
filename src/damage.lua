-- What a hit was worth, thrown up off the thing it landed on.
--
-- Until this existed the only account the page gave of a hit was a flash and two
-- red specks, which says *that* something landed and never says how hard -- so a
-- draft that doubled a tool's damage looked exactly like one that did nothing,
-- and the whole upgrade half of the game was invisible while you played it. A
-- number is the cheapest possible fix for that, and the only one that reads at a
-- glance in the middle of a horde.
--
-- Three decisions run through the whole module.
--
-- **It is drawn over the page, not on it.** Every number goes down after
-- Overprint.finish(), alongside the HUD and the draft's cards. That is not just
-- layering: inside the ink pass a red number crossing a ruled line would come
-- out slate and a blush one would come out red (Palette.overprint), so the
-- colours picked below would mean one thing on blank paper and another on
-- squared -- and the one thing a readout may not do is change colour because of
-- what happens to be printed underneath it. Over the pass they are exactly the
-- eight colours they were set to, everywhere.
--
-- **The pop steps between whole scales.** Nothing in this game is drawn at a
-- fractional size, so a number cannot ease up from nothing the way a number in
-- an ordinary game does. It arrives one whole step *over* the size it lands at,
-- drops to it, and drops one under it again on the way out -- three sizes, no
-- tweening. That reads as a stamp rather than a zoom, which is the right feel
-- for a page made of pixels, and it is the only shape of pop the rendering rules
-- allow.
--
-- **How big it is, is what it says.** The tier table below is the whole design:
-- a hit under ten is a small light-red number, and everything above that gets
-- bigger, heavier and more outlined until a killing blow off a late-run build is
-- a white number three times the size with a red edge and an ink rim round it.
-- Nothing has to read the value -- a run getting stronger *looks* like the page
-- filling with fatter numbers, and that is the whole point.

local Palette = require("src.palette")
local Font = require("src.font")

local Damage = {}
Damage.__index = Damage

-- Up to `upto` damage, drawn like this. The last row has no ceiling.
--
-- Every tier is outlined and none of them may not be: a number with no ring
-- round it is unreadable the moment it crosses ink, and this is a game whose
-- page is made of ink. Fill and ring are palette names rather than colours, so
-- nothing here can invent a ninth one.
local TIERS = {
    -- Small hits: light red, at scale 1. Most of the numbers on the page are
    -- these and they have to be able to be *ignored*, which is what keeps them
    -- the smallest thing here and the palest fill in the table.
    --
    -- The ring is ink rather than the darker red it wants to be, and that is a
    -- palette fact rather than a choice: there is no darker red -- `red` is
    -- already the bottom of that ramp -- so blush ringed in red is two
    -- neighbouring pinks with nothing between them, and a 4 drawn in it is a
    -- smudge at this size. Ink is the honest stand-in for the dark red the
    -- palette does not have, and it is what makes a one-scale number legible
    -- over squared paper at all.
    { upto = 9,  scale = 1, fill = "blush", ring = "ink" },
    -- Past what a chaff enemy has in it: same size, same ring, fill up to full
    -- red. A step you feel rather than read, which is right -- the difference
    -- between a 9 and a 10 is not the one worth shouting about.
    { upto = 24, scale = 1, fill = "red", ring = "ink" },
    -- Past what a skull has, and the size doubles. White on red: paper is the
    -- one colour in the palette that reads as lying *on top of* the page rather
    -- than being drawn on it -- it is what the draft's cards and the pause card
    -- are filled with for the same reason -- so this is the tier where a number
    -- stops being a mark and starts being a thing thrown at you.
    { upto = 49, scale = 2, fill = "paper", ring = "red" },
    -- Everything else, at three times the size and back to the ink ring, which
    -- is the only one that still holds a figure this big off a busy page. A crit
    -- off a built run lands here and it should be the loudest thing on screen
    -- for the third of a second it is up.
    { scale = 3, fill = "paper", ring = "ink" },
}

local RISE = 34    -- how fast a number leaves the thing it came off
local FALL = 62    -- and what pulls it back down, so it arcs rather than drifts
local DRIFT = 16   -- sideways spread, so two hits a frame apart don't stack
local SPREAD = 4   -- and how far off centre one may start, for the same reason

local POP = 0.07     -- how long it is drawn a size over the one it lands at
local SHRINK = 0.13  -- and how long it is drawn a size under it, on the way out
local LIFE = 0.42    -- how long the smallest number lasts...
local LIFE_PER = 0.16 -- ...and what each step of size adds to that

-- A ceiling on how many may be in the air at once. The brief was explicitly that
-- a page full of numbers is part of the fun, so this is set well above what a
-- busy screen produces (the run-clock batching in Game:spendHits is what
-- actually keeps the count sane) and exists only so that a pathological frame --
-- a full arena caught in a beam, a ring of tears landing together -- cannot turn
-- into a few thousand quad draws. The oldest go first: they were fading anyway.
local MAX = 140

local function tierFor(amount)
    for i = 1, #TIERS - 1 do
        if amount <= TIERS[i].upto then return TIERS[i] end
    end
    return TIERS[#TIERS]
end

function Damage.new()
    return setmetatable({ list = {} }, Damage)
end

-- `amount` is whatever the damage actually was, fractions and all: every
-- multiplier a run owns is a float, so almost nothing hits for a round number.
-- It is rounded here rather than anywhere upstream -- what the enemy lost is the
-- real figure and what the page says is a reading of it -- and floored at 1,
-- because a tick that took a tenth of a point off something still happened and a
-- "0" floating off an enemy reads as a bug.
function Damage:add(x, y, amount)
    local n = math.max(1, math.floor(amount + 0.5))
    local tier = tierFor(n)

    -- Bigger numbers hang about longer, which is most of why they land harder:
    -- a 3 is gone before you have finished reading it and a 60 is on the page
    -- long enough to be looked at.
    local life = LIFE + tier.scale * LIFE_PER

    self.list[#self.list + 1] = {
        text = tostring(n),
        tier = tier,
        -- Started off centre and drifting, so a stream of hits on one enemy
        -- comes out as a spray of numbers instead of one number redrawn.
        x = x + (love.math.random() * 2 - 1) * SPREAD,
        y = y,
        dx = (love.math.random() * 2 - 1) * DRIFT,
        dy = -RISE,
        life = life,
        born = life,
    }

    if #self.list > MAX then table.remove(self.list, 1) end
end

function Damage:update(dt)
    for i = #self.list, 1, -1 do
        local n = self.list[i]
        n.x = n.x + n.dx * dt
        n.y = n.y + n.dy * dt
        n.dy = n.dy + FALL * dt
        n.life = n.life - dt
        if n.life <= 0 then table.remove(self.list, i) end
    end
end

-- The three beats of the pop, in order: a size over what it lands at, the size
-- it lands at, and a size under it on the way out. The last beat also goes
-- `flat` -- the whole figure in the ring's colour, fill and all -- which is what
-- turns the exit into ink lifting off the page rather than a number blinking
-- out, and is the only shrink available at all to a number already at scale 1.
local function beat(n)
    local age = n.born - n.life
    if age < POP then return n.tier.scale + 1, false end
    if n.life < SHRINK then return math.max(1, n.tier.scale - 1), true end
    return n.tier.scale, false
end

-- Drawn in world space, so this is called inside the camera transform.
function Damage:draw()
    for _, n in ipairs(self.list) do
        local scale, flat = beat(n)
        local w = Font.boldWidth(n.text, scale)
        -- Centred on where the hit landed and hung off its own bottom edge, so
        -- growing a size pushes the number up and out of the crowd rather than
        -- down into it, and so the three sizes stay over the same spot instead
        -- of walking sideways as they change.
        local x = math.floor(n.x - w / 2)
        local y = math.floor(n.y) - Font.boldTall(scale)

        love.graphics.setColor(Palette[n.tier.ring])
        Font.printBoldRing(n.text, x, y, scale)

        love.graphics.setColor(Palette[flat and n.tier.ring or n.tier.fill])
        Font.printBold(n.text, x, y, scale)
    end
end

return Damage
