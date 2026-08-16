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
    -- Chip damage, and the only tier drawn in the small face (5x5 rather than
    -- 5x7, src/font.lua). A blob is 8 pixels tall and the ordinary face in its
    -- outlined cell is 9, so every other tier stands taller than the monster it
    -- came off; this one does not, which is the whole of what it is saying.
    --
    -- It is also the only tier whose ring is red rather than ink, so it is the
    -- one number here that does not fully hold itself off the page -- blush
    -- ringed in red is two neighbouring pinks, since `red` is already the bottom
    -- of that ramp and there is no darker red to reach for. Same intent: a hit
    -- that barely happened should be the thing your eye skips over.
    { upto = 5,  scale = 1, fill = "blush", ring = "red", small = true,
      steady = true },
    -- The same light fill at the ordinary size, held off the page properly. Ink
    -- is the honest stand-in for the dark red the palette does not have, and
    -- from here down every tier has it: it is what makes a one-scale number
    -- legible over squared paper at all.
    { upto = 12, scale = 1, fill = "blush", ring = "ink", steady = true },
    -- Past what most chaff has in it, and the fill comes up to full red. Same
    -- size, same ring -- but this is the first tier that pops, and that is what
    -- actually marks the step: from here up, a number announces itself by
    -- arriving a size over and settling, and below it they simply appear.
    { upto = 24, scale = 1, fill = "red", ring = "ink" },
    -- Past what a skull has, and the size doubles. Paper is the one colour in
    -- the palette that reads as lying *on top of* the page rather than being
    -- drawn on it -- it is what the draft's cards and the pause card are filled
    -- with, for the same reason -- so this is where a number stops being a mark
    -- and starts being a thing thrown at you. Ringed red while it is still the
    -- lighter half of that jump.
    { upto = 35, scale = 2, fill = "paper", ring = "red" },
    -- The heavier half: same white, same size, ink round it. Maximum contrast,
    -- and the loudest a number gets before it also gets bigger.
    { upto = 49, scale = 2, fill = "paper", ring = "ink" },
    -- Everything else, at three times the size and back to blush. Nothing needs
    -- to be doing the work of standing out by then -- a figure this big is
    -- unmissable on its size alone -- so the fill goes back to the softest one
    -- in the table and the ink ring carries it. A crit off a built run lands
    -- here, and it should be the loudest thing on screen for the third of a
    -- second it is up.
    { scale = 3, fill = "blush", ring = "ink" },
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
-- it lands at, and a size under it on the way out.
--
-- A `steady` tier skips the first of those and simply appears at its size. The
-- overshoot doubles a number for the length of the beat, and on a one-scale tier
-- that means the first thing you see of it is a figure more than twice as tall
-- as the enemy underneath -- which, on the tiers that make up most of the
-- numbers a run throws, is the whole page shouting about chip damage. The pop is
-- worth having where the hit is worth announcing, so it starts at the tier that
-- is worth announcing and the two below it stay put.
--
-- The last beat goes `hollow` -- the ring drawn and the figure inside it left
-- empty, so the fill lifts off the page and the outline of the number goes a
-- moment later. That is doing two jobs. It reads as ink coming away rather than
-- a number being switched off, and it is the only exit the three one-scale tiers
-- have at all, since there is no size under 1 to drop to.
--
-- The obvious alternative -- the whole figure in one colour, fill and ring
-- together -- was tried and is a solid rectangle at every size the face is
-- drawn at. A number that ends its life as a blob reads as a bug.
local function beat(n)
    local age = n.born - n.life
    if not n.tier.steady and age < POP then return n.tier.scale + 1, false end
    if n.life < SHRINK then return math.max(1, n.tier.scale - 1), true end
    return n.tier.scale, false
end

-- Drawn in world space, so this is called inside the camera transform.
function Damage:draw()
    for _, n in ipairs(self.list) do
        local scale, hollow = beat(n)
        -- The two faces are the same width and differ only in height, so which
        -- one a tier uses changes how tall its numbers stand and nothing else
        -- about how they are placed.
        local face = n.tier.small and Font.boldSmall or Font.bold
        -- Centred on where the hit landed and hung off its own bottom edge, so
        -- growing a size pushes the number up and out of the crowd rather than
        -- down into it, and so the three sizes stay over the same spot instead
        -- of walking sideways as they change.
        local x = math.floor(n.x - face:width(n.text, scale) / 2)
        local y = math.floor(n.y) - face:tall(scale)

        -- Every ring of the number before any of its bodies, and all in one
        -- colour. The face is pitched a pixel tighter than its own cell so that
        -- two digits share the padding between them (src/font.lua), which is
        -- only safe while that order holds: ring landing on ring is invisible,
        -- ring landing on a figure would not be.
        love.graphics.setColor(Palette[n.tier.ring])
        face:printRing(n.text, x, y, scale)

        if not hollow then
            love.graphics.setColor(Palette[n.tier.fill])
            face:print(n.text, x, y, scale)
        end
    end
end

return Damage
