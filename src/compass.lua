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
function Compass:cut(game, from, to)
    local def = self.def

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if not self.hit[e] then
            local dx, dy = e.x - self.x, e.y - self.y
            local reach = self.radius + e.radius

            if dx * dx + dy * dy <= reach * reach then
                local a = math.atan2(dy, dx)
                local round = (a - self.start) % TAU

                if round >= from and round < to then
                    self.hit[e] = true

                    -- Dragged round the circle rather than shoved out of it:
                    -- the leg takes what it catches with it. A horde standing
                    -- in one comes out stirred rather than scattered, which is
                    -- what keeps this from being a round ruler.
                    e:knockback(-math.sin(a), math.cos(a), def.knock)

                    game.particles:burst(e.x, e.y, 2, Palette.red)
                    if e:hurt(def.damage) then
                        game:killEnemy(i)
                    end
                end
            end
        end
    end
end

-- Returns false once the circle it drew has faded off the page. Nothing ages
-- while it is open: a compass held on the page waits as long as you hold it,
-- and the horde keeps walking the whole time.
function Compass:update(dt, game)
    if self.setting then return true end

    if self.swept < TAU then
        local from = self.swept
        self.swept = math.min(TAU, self.swept + TAU * dt / self.def.turn)
        self:cut(game, from, self.swept)

        -- Graphite jumping off the lead, so the arm reads as drawing the line
        -- rather than uncovering one that was already there.
        self.speck = self.speck - (self.swept - from)
        if self.speck <= 0 then
            self.speck = SPECK
            local a = self.start + self.swept
            game.particles:burst(self.x + math.cos(a) * self.radius,
                                 self.y + math.sin(a) * self.radius,
                                 1, Palette.graphite)
        end
        return true
    end

    self.age = self.age + dt
    return self.age < self.def.life
end

-- The rim, plotted a pixel at a time on the grid rather than as a polygon, so
-- the circle sits on the same lattice as the ruling under it. `upTo` is how far
-- round the lead has got, `dash` leaves the gaps a pencil guide is drawn with,
-- and `dither` drops points out exactly the way a fading stroke drops stamps.
function Compass:plot(upTo, dash, dither)
    local n = self.steps
    local last = math.min(n - 1, math.floor(upTo / TAU * n))
    local cx, cy, r = self.x, self.y, self.radius

    for i = 0, last do
        if (not dash or i % (dash * 2) < dash)
            and (not dither or util.hash01(i, self.seed, 31) > dither) then
            local a = self.start + TAU * i / n
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
    if self.setting then
        -- Ruled out in pencil first, the way the ruler's band is. What is being
        -- chosen is a circle, so a circle is what you are shown -- a radius
        -- read off the leg alone would be a number, not a target.
        love.graphics.setColor(Palette.graphite)
        self:plot(TAU, DASH, nil)
        return
    end

    local def = self.def

    if self.swept < TAU then
        -- Still coming round, and full ink: this is the line being drawn.
        love.graphics.setColor(def.ramp[1])
        self:plot(self.swept, nil, nil)
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
    self:plot(TAU, nil, dither)
end

-- The instrument itself, for as long as it is standing in the page. It is an
-- object on the paper rather than a mark in it, so it is drawn over the top of
-- everything -- including whatever is standing in the circle, because a leg you
-- cannot see behind a blob is a leg you cannot tell the width of. The moment the
-- circle closes the compass is lifted off and only the line it drew is left.
function Compass:draw()
    if not self.setting and self.swept >= TAU then return end

    local a = self.start + self.swept
    local ca, sa = math.cos(a), math.sin(a)
    local cx, cy = math.floor(self.x), math.floor(self.y)

    -- The leg, out to the lead. Plotted a pixel at a time for the same reason
    -- the rim is. Pencil-pale while it is being set, inked once it is drawing.
    love.graphics.setColor(self.setting and Palette.graphite or Palette.slate)
    pixelart.line(self.x, self.y, self.x + ca * self.radius, self.y + sa * self.radius)

    -- The lead, pressed into the paper at the end of it.
    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill",
        math.floor(self.x + ca * self.radius) - 1,
        math.floor(self.y + sa * self.radius) - 1, 2, 2)

    -- The needle. Red-headed, because it is the one point of the whole figure
    -- that never moves and the only part of it you placed by hand.
    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", cx, cy - NEEDLE, 1, NEEDLE)
    love.graphics.setColor(Palette.red)
    love.graphics.rectangle("fill", cx - 1, cy - NEEDLE - 2, 3, 2)
end

return Compass
