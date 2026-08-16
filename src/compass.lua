-- A pair of compasses, stood in the page and swung.
--
-- The fourth way a tool can be used. A brush is dragged and the mark is
-- wherever you dragged it; a pin is tapped and lands where you tapped; a ruler
-- is aimed about the player and comes down when you let go. A compass is
-- *opened*: press and the needle goes into the page right there, drag and the
-- pencil leg opens out to however wide you want the circle, let go and it
-- draws.
--
-- One gesture, and the same one the real instrument is set with -- the needle
-- stays where you put it and the other leg swings out from it. It also means
-- the circle is placed before it is sized, which is the opposite way round from
-- every other tool here: everywhere else you commit to where a mark goes by
-- dragging, and the size is whatever the drag came to.
--
-- Which makes it the slowest thing in the game to bring to bear, and the only
-- one whose hit you can watch travel. Nothing happens at the moment you release:
-- the lead sets off from wherever you left it resting and cuts what it passes
-- over as it arrives there, so the far side of a wide circle has most of a turn
-- to walk out of it -- and can see the arm coming the whole way round. It is
-- the one attack in the game that is a promise for most of a second.
--
-- It is also the only tool that reaches away from the player. The ruler pivots
-- about you and the crayon lane starts under your feet; a compass is stood
-- wherever you tapped, which means the circle can be drawn round a crowd you
-- are not standing in. The screen is the whole of the limit on that, exactly as
-- it is for the pushpin.
--
-- The needle is what costs. It goes in on the press and the ink goes with it,
-- so a compass that has been opened always draws its circle: if something else
-- takes it away first -- a tool change, the pause -- it swings at whatever width
-- it had reached rather than handing the ink back.
--
-- Everything the upgrade line adds is a variation on that one journey rather
-- than a new thing the tool does: the leg bites hardest over the first stretch
-- of it, it may go round more than once, and a second leg may set off the other
-- way. All three are read off the sweep block, and none of them changes what the
-- gesture is.

local Palette = require("src.palette")
local pixelart = require("src.pixelart")
local util = require("src.util")

local Compass = {}
Compass.__index = Compass

local TAU = math.pi * 2
local DASH = 3        -- pencil dashes the guide circle is ruled out with
local SPECK = TAU / 10 -- radians between flecks of graphite off the lead
local NEEDLE = 5      -- how far the needle stands out of the page

-- How many points get plotted round the rim. Fixed for a given radius, so a
-- point keeps its index for the whole life of the mark -- which is what lets
-- the dither pick the same ones every frame as it fades, instead of boiling.
local function stepsFor(r)
    return math.max(24, math.floor(TAU * r * 1.5))
end

function Compass.new(def, x, y)
    return setmetatable({
        def = def,
        x = x, y = y,       -- the needle: wherever you tapped
        radius = def.minR,
        start = 0,          -- where the lead rests, and so where it sets off from
        steps = stepsFor(def.minR),
        setting = true,     -- still open in your hand
        swept = 0,          -- radians come round so far
        -- A lap is the circle closed, not a leg going all the way round: two
        -- legs each walk half of it and meet on the far side. That is what
        -- makes the second leg worth a level -- the rim is finished in half the
        -- time -- and it is why nothing below measures a lap against TAU.
        span = TAU / (def.counter and 2 or 1),
        total = TAU * def.laps / (def.counter and 2 or 1),
        lap = 0,            -- which time round the hit list belongs to
        age = 0,
        hit = {},
        speck = SPECK,
        seed = love.math.random() * 997,
    }, Compass)
end

-- How far you have dragged from the needle is how wide it is, and the direction
-- you dragged in is where the lead is left resting -- which is where it sets off
-- from. So one drag picks the size of the circle and which part of it gets cut
-- first, and there is nothing else to aim.
--
-- The drag starts on the needle, so a press with no drag in it at all is a
-- circle at the minimum width: the quickest thing the tool can do, and still a
-- deliberate one, since the whole meter price was paid to press at all.
function Compass:reachTo(px, py)
    local dx, dy = px - self.x, py - self.y
    local d = util.len(dx, dy)

    self.radius = util.clamp(d, self.def.minR, self.def.maxR)
    self.steps = stepsFor(self.radius)

    -- A pointer sat on the needle has no direction in it; keeping the last
    -- angle is what stops the leg spinning as the drag leaves the anchor.
    if d > 1 then self.start = math.atan2(dy, dx) end
end

function Compass:swing()
    self.setting = false
end

-- Everything the leg passed over between one frame and the last. The band is
-- measured round from where the lead set off rather than in absolute angles, so
-- it only ever runs forwards and the bands tile the turn exactly: nothing is
-- cut twice, and nothing is skipped however fast the arm is moving. An enemy
-- that wanders in behind the lead is not cut, because the lead has been past.
--
-- A second leg, if the run has drafted one, covers the same band measured the
-- other way round -- so the two of them set off together and meet on the far
-- side, and the circle is closed in half a turn instead of a whole one. They
-- share the hit list, because what the two legs buy is the far side being
-- reached sooner rather than everything being cut twice.
--
-- `closes` says this band finishes the lap, and it is what keeps the promise
-- above honest once there are two legs: they divide the turn at exactly one
-- angle each, and something standing dead on the join would otherwise fall
-- between the two of them rather than be cut by either.
function Compass:cut(game, from, to, closes)
    local def = self.def

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if not self.hit[e] then
            local dx, dy = e.x - self.x, e.y - self.y
            local reach = self.radius + e.radius

            if dx * dx + dy * dy <= reach * reach then
                local a = math.atan2(dy, dx)
                local round = (a - self.start) % TAU

                -- Which leg reached it, and how far round that leg had come
                -- when it did. Nothing is left of the second one when the tool
                -- has only the one, since `back` is never tested.
                local dir, at
                if round >= from and (round < to or (closes and round <= to)) then
                    dir, at = 1, round
                elseif def.counter then
                    local back = (-round) % TAU
                    if back >= from and (back < to or (closes and back <= to)) then
                        dir, at = -1, back
                    end
                end

                if dir then
                    self.hit[e] = true

                    -- Dragged round the circle rather than shoved out of it:
                    -- the leg takes what it catches with it, the way that leg
                    -- is going. A horde standing in one comes out stirred
                    -- rather than scattered, which is what keeps this from
                    -- being a round ruler.
                    e:knockback(-math.sin(a) * dir, math.cos(a) * dir, def.knock)

                    -- The lead bites deepest over the stretch it sets off on,
                    -- and that stretch is the one thing about a compass you get
                    -- to aim: the drag picks the width, and the direction you
                    -- dragged in is where the biting starts. Measured per lap,
                    -- so going round again bites again.
                    local damage = def.damage
                    if at < def.biteArc then damage = damage * def.bite end

                    game.particles:burst(e.x, e.y, 2, Palette.red)
                    if e:hurt(damage) then
                        game:killEnemy(i)
                    end
                end
            end
        end
    end
end

-- Where a leg's lead is now, as an offset from the needle. `dir` is 1 for the
-- leg that goes with the turn and -1 for the second one, which comes round the
-- other way from the same rest point.
function Compass:leadAt(dir)
    local a = self.start + dir * self.swept
    return math.cos(a) * self.radius, math.sin(a) * self.radius
end

-- The leg moved on, and everything under it cut. The band is walked a lap at a
-- time rather than in one go, because the hit list is what a lap *is*: coming
-- round a second time only means anything if what was cut on the way past can
-- be cut again. The arm always moves at a whole turn per `turn` seconds, so a
-- circle that goes round twice takes twice as long and one closed by two legs
-- takes half -- the promise gets longer or shorter, never the arm faster.
function Compass:advance(dt, game)
    local target = math.min(self.total, self.swept + TAU * dt / self.def.turn)

    while self.swept < target do
        local lap = math.floor(self.swept / self.span)
        local base = lap * self.span

        if lap ~= self.lap then
            self.lap = lap
            self.hit = {}
        end

        local edge = math.min(target, base + self.span)
        self:cut(game, self.swept - base, edge - base, edge >= base + self.span)
        self.swept = edge
    end
end

-- Returns false once the circle it drew has faded off the page. Nothing ages
-- while it is open: a compass held on the page waits as long as you hold it,
-- and the horde keeps walking the whole time.
function Compass:update(dt, game)
    if self.setting then return true end

    if self.swept < self.total then
        local from = self.swept
        self:advance(dt, game)

        -- Graphite jumping off the lead, so the arm reads as drawing the line
        -- rather than uncovering one that was already there. Red off the
        -- stretch it bites on, which is the blue the needle's head is drawn in:
        -- the parts of the figure that are doing something rather than being
        -- somewhere.
        self.speck = self.speck - (self.swept - from)
        if self.speck <= 0 then
            self.speck = SPECK

            local color = Palette.graphite
            if self.swept % self.span < self.def.biteArc and self.def.bite > 1 then
                color = Palette.blue
            end

            local ox, oy = self:leadAt(1)
            game.particles:burst(self.x + ox, self.y + oy, 1, color)
            if self.def.counter then
                ox, oy = self:leadAt(-1)
                game.particles:burst(self.x + ox, self.y + oy, 1, color)
            end
        end
        return true
    end

    self.age = self.age + dt
    return self.age < self.def.life
end

-- The rim, plotted a pixel at a time on the grid rather than as a polygon, so
-- the circle sits on the same lattice as the ruling under it. `a0` and `a1` are
-- how far round from where the lead set off the stretch runs -- past a full turn
-- is clamped to one, since a second lap goes over ink that is already there --
-- `dash` leaves the gaps a pencil guide is drawn with, `dither` drops points out
-- exactly the way a fading stroke drops stamps, and `dir` is which way round,
-- for the second leg.
function Compass:plot(a0, a1, dash, dither, dir)
    local n = self.steps
    local first = math.max(0, math.ceil(a0 / TAU * n))
    local last = math.min(n - 1, math.floor(a1 / TAU * n))
    local cx, cy, r = self.x, self.y, self.radius
    dir = dir or 1

    for i = first, last do
        if (not dash or i % (dash * 2) < dash)
            and (not dither or util.hash01(i, self.seed, 31) > dither) then
            local a = self.start + dir * TAU * i / n
            love.graphics.rectangle("fill",
                math.floor(cx + math.cos(a) * r),
                math.floor(cy + math.sin(a) * r), 1, 1)
        end
    end
end

-- The page's share of it: where the circle is going to go, the part of it that
-- has been drawn so far, and the finished ring fading. All three are marks, so
-- all three go under everything standing on the page.
function Compass:drawGuide()
    local def = self.def

    if self.setting then
        -- Ruled out in pencil first, the way the ruler's band is. What is being
        -- chosen is a circle, so a circle is what you are shown -- a radius
        -- read off the leg alone would be a number, not a target.
        love.graphics.setColor(Palette.graphite)
        self:plot(0, TAU, DASH, nil)

        -- And the stretch that bites, in the needle's own blue, over the top of
        -- it. The drag is choosing two things at once and this is the second of
        -- them: turning the leg round the crowd puts the deep cut where you
        -- want it, and without the blue the choice would be invisible.
        if def.bite > 1 then
            love.graphics.setColor(Palette.blue)
            self:plot(0, def.biteArc, DASH, nil)
            if def.counter then self:plot(0, def.biteArc, DASH, nil, -1) end
        end
        return
    end

    if self.swept < self.total then
        -- Still coming round, and full ink: this is the line being drawn.
        love.graphics.setColor(def.ramp[1])
        self:plot(0, self.swept, nil, nil)
        if def.counter then self:plot(0, self.swept, nil, nil, -1) end
        return
    end

    -- Closed, and leaving the page the way every other mark does -- down a
    -- ramp, dithering out, never through an alpha that would invent a ninth
    -- colour.
    local f = self.age / def.life
    local ramp = def.ramp
    local dither
    if f > def.fade then dither = (f - def.fade) / (1 - def.fade) end

    love.graphics.setColor(ramp[math.min(#ramp, math.floor(f * #ramp) + 1)])
    self:plot(0, TAU, nil, dither)
end

-- The instrument itself, for as long as it is standing in the page. It is an
-- object on the paper rather than a mark in it, so it is drawn over the top of
-- everything -- including whatever is standing in the circle, because a leg you
-- cannot see behind a blob is a leg you cannot tell the width of. The moment the
-- circle closes the compass is lifted off and only the line it drew is left.
function Compass:draw()
    if not self.setting and self.swept >= self.total then return end

    local cx, cy = math.floor(self.x), math.floor(self.y)

    self:drawLeg(1)
    if self.def.counter then self:drawLeg(-1) end

    -- The needle. Blue-headed, because it is the one point of the whole figure
    -- that never moves and the only part of it you placed by hand -- and what
    -- you placed by hand is blue everywhere on this page.
    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", cx, cy - NEEDLE, 1, NEEDLE)
    love.graphics.setColor(Palette.blue)
    love.graphics.rectangle("fill", cx - 1, cy - NEEDLE - 2, 3, 2)
end

-- One leg, out to its lead. Plotted a pixel at a time for the same reason the
-- rim is. Pencil-pale while it is being set, inked once it is drawing.
function Compass:drawLeg(dir)
    local ox, oy = self:leadAt(dir)

    love.graphics.setColor(self.setting and Palette.graphite or Palette.slate)
    pixelart.line(self.x, self.y, self.x + ox, self.y + oy)

    -- The lead, pressed into the paper at the end of it -- and pressed harder
    -- over the stretch it bites on, which is the only warning anything standing
    -- there gets that this part of the circle is worth twice the rest of it.
    local wide = not self.setting and self.def.bite > 1
        and self.swept % self.span < self.def.biteArc
    local w = wide and 3 or 2

    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill",
        math.floor(self.x + ox) - 1, math.floor(self.y + oy) - 1, w, w)
end

return Compass
