-- A ruler, snapped down flat against the page.
--
-- The third way a tool can be used, after the brushes and the pushpin. A brush
-- is held and dragged and the mark is wherever you dragged it; a pin is tapped
-- and lands where you tapped. A ruler is *aimed*: press and the line appears
-- through you, drag and it pivots about you, and the moment you let go the
-- ruler comes down flat on everything lying along it.
--
-- Which makes it the one tool you point rather than place. The pivot is the
-- player, so the shot is always through yourself -- you cannot reach across the
-- page with it, you can only decide which way the page gets swept -- and the
-- pivot follows you while you aim, so walking is part of lining it up rather
-- than something you have to stop doing to use it.
--
-- Nothing about the aim is free. The press pays for it and the release lands
-- it: there is no letting go of a ruler without hitting the page with it, and
-- the horde keeps walking the whole time you are lining it up.
--
-- **And some rulers are not aimed at all.** A fusion may hand this file two
-- points and ask for the ruler that goes with them (`Ruler.cast`, the FOLD and
-- the SNAP LINE in src/tools.lua): two compass circles that overlap cross at
-- exactly two places and the line joining those two places is what the pair of
-- instruments was bought to construct, and two pushpins a hundred and twenty
-- pixels apart are a
-- pair of sights aiming a line neither of them is an end of. So there is no pivot
-- to walk, no angle to turn and nothing to let go of -- the ruler is built already
-- lying on the line and comes down on the frame it is made.
--
-- Which is the one thing that had to change here for it, and it is one field:
-- how far the ruler reaches either side of its pivot is a number *this* ruler
-- carries rather than one read off the block every time it is wanted. An aimed
-- one is as long as the tool has been upgraded to be; a cast one is as long as
-- whoever cast it says.
--
-- **And there are two things casting can mean**, which `Ruler.cast` picks between
-- on one field. Two points may be the *ends* of the line -- the FOLD's two
-- crossings, where no level of anything may make the ruler longer than the
-- circles left it -- or they may be the *aim* of it, two pushpins a hundred and
-- twenty pixels apart standing in for a pair of sights, in which case the reach is
-- the tool's
-- own and the line runs on past both of them to the corners of the page (the SNAP
-- LINE, src/tools.lua). Bounded by two points, or aimed by them. See Ruler.cast.
--
-- **And a ruler may be carrying something**, which is the seven rows at the foot
-- of src/tools.lua and is the last thing this file had to learn. A ruler is
-- aimed and lands exactly as it always did; what is new is that whatever else is
-- on the row is then ruled *along the line it just landed on* -- a pencil line, a
-- fence, a burning band, a bar of paste, a seam of staples, the page opened. None
-- of that is here. It is `Game:trailRuler`, for the reason a thread is in
-- src/game.lua and not in src/pin.lua: what happens along a line is not the
-- straight edge's business, and the only thing this file owes it is where the two
-- ends are (`Ruler:ends`, which was already public).
--
-- One field of it is here, because it is about what the ruler *reaches* rather
-- than about what is left behind. `wipe` on the block takes the band off: what a
-- ruler with one lands on is every body within its own length of the line, which
-- on a ruler ruling the whole page is the whole page. It is the compass's field
-- of the same name in the other block (the CLEARING) and it means the same thing
-- -- what the block reaches, not by how much -- and it has the same consequence
-- for the aim, which Compass:drawGuide already lives with: the dashes still draw
-- the band, because the band is still the object, and the reach is not a thing
-- this tool was ever going to be able to draw.

local Palette = require("src.palette")
local util = require("src.util")

local Ruler = {}
Ruler.__index = Ruler

local SLAP = 0.14   -- how long the ruler itself lies on the page after it lands
local DEAD = 4      -- pointer this close to the pivot leaves the angle alone
local DASH = 3      -- pencil dash marking out where it will land
local TICK = 8      -- pixels between graduations

function Ruler.new(def, x, y, length)
    return setmetatable({
        def = def,
        x = x, y = y,      -- the pivot: the player, unless it was cast
        -- How far it reaches either side of that pivot. The tool's own length,
        -- unless whatever cast it had a shorter one in mind (Ruler.cast).
        length = length or def.length,
        angle = 0,
        aiming = true,
        age = 0,
        slap = 0,
        seed = love.math.random() * 997,
    }, Ruler)
end

-- The pivot is the player, not the spot the press landed on, so the whole line
-- comes along while you walk.
function Ruler:follow(x, y)
    self.x, self.y = x, y
end

function Ruler:aimAt(px, py)
    local dx, dy = px - self.x, py - self.y
    -- A pointer sat on top of the pivot has no direction in it; keeping the
    -- last angle is what stops the line spinning when you drag across yourself.
    if dx * dx + dy * dy < DEAD * DEAD then return end
    self.angle = math.atan2(dy, dx)
end

-- A ruler nobody aimed: laid flat along the line through two points somebody
-- else worked out.
--
-- The pivot goes in the middle of the gap, so `ends` is symmetrical about it and
-- the caller never has to know that a ruler is a line *through* a pivot rather
-- than a line from A to B.
--
-- **How far it then reaches is decided by whether the row wrote a length down**,
-- and that one `or` is the whole difference between the two things a cast can
-- mean. The FOLD leaves `snap.length` unwritten because the chord decides it --
-- two circles crossing hand over two points and the ruler is the line *between*
-- them, no longer and no shorter -- so the gap's own half is the reach and the
-- ends land exactly on the two crossings. The SNAP LINE writes it, because there
-- the two points are not the ends of anything: they are pins a hundred and twenty
-- pixels apart being used as *sights*, and what they decide is the angle. So the reach is the
-- tool's own and the line runs on past both of them to the corners of the page.
--
-- Aimed by two points against bounded by two points, in one field either written
-- or not. Neither row needed a flag and neither caller needed an argument.
--
-- Nothing is being aimed, so there is nothing to release: whatever cast it lands
-- it on the same frame (Game:castRuler).
function Ruler.cast(def, ax, ay, bx, by)
    local r = Ruler.new(def, (ax + bx) / 2, (ay + by) / 2,
        def.length or util.len(bx - ax, by - ay) / 2)
    r.angle = math.atan2(by - ay, bx - ax)
    return r
end

-- Both ends of it. A ruler is a line through you rather than a beam out of you,
-- so it reaches the same distance behind as in front.
function Ruler:ends()
    local L = self.length
    local cx, cy = math.cos(self.angle), math.sin(self.angle)
    return self.x - cx * L, self.y - cy * L,
           self.x + cx * L, self.y + cy * L
end

-- One hit each, everything lying along it, and shoved clear of the line rather
-- than along it: the page is swept to both sides at once and what is left is a
-- corridor. Backwards, because a kill takes an enemy out of the list under us.
function Ruler:strike(game)
    self.aiming = false
    self.slap = SLAP

    local def = self.def
    local ax, ay, bx, by = self:ends()
    local dx, dy = math.cos(self.angle), math.sin(self.angle)

    -- How far off the line a body's centre may be before its own radius stops
    -- reaching -- the band, unless the row took the band off (`wipe`, the PARTING
    -- in src/tools.lua), in which case it is the ruler's own reach: a straight
    -- edge as long as the page, reaching as far to either side as it is long, is
    -- a straight edge that reaches all of it. Measured off `length` rather than
    -- off a number of its own so that it is the *same* screen the finale
    -- measured, and so an unfinished one parts less page than a finished one.
    local reach = def.wipe and self.length or def.width

    -- Graphite jumping off the page along its whole length, so the slap reads
    -- as a slap rather than a line appearing.
    for i = 0, 4 do
        local t = i / 4
        game.particles:burst(ax + (bx - ax) * t, ay + (by - ay) * t, 2, Palette.graphite)
    end

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if util.distToSegment(e.x, e.y, ax, ay, bx, by) < reach + e.radius then
            -- Which side of the line it is standing on decides which way it
            -- goes; anything caught exactly under the edge picks one.
            local side = (e.x - self.x) * -dy + (e.y - self.y) * dx
            local s = side >= 0 and 1 or -1
            e:knockback(-dy * s, dx * s, def.knock)

            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(def.damage) then
                game:killEnemy(i)
            end
        end
    end
end

-- Returns false once the line it ruled has faded off the page. An aim is held
-- for as long as you hold it: nothing ages until the ruler has come down.
function Ruler:update(dt, game)
    if self.aiming then return true end

    self.age = self.age + dt
    self.slap = math.max(0, self.slap - dt)
    return self.age < self.def.life
end

-- Everything here is drawn along the line rather than across the page, so it is
-- all laid out flat about the origin and turned once. The pivot is floored so
-- the turn happens on the pixel grid rather than a third of the way into it.
function Ruler:transform()
    love.graphics.push()
    love.graphics.translate(math.floor(self.x), math.floor(self.y))
    love.graphics.rotate(self.angle)
end

-- The page's share of it: where the ruler is going to land, and the line it
-- left once it has been lifted off again. Both are marks, so both go under
-- everything standing on the page.
function Ruler:drawGuide()
    local L, W = self.length, self.def.width
    self:transform()

    if self.aiming then
        -- Ruled out in pencil first, the way you would: the two long edges and
        -- the ends, so what is being aimed is the band it covers rather than a
        -- hairline that turns out to be fifteen pixels wide.
        love.graphics.setColor(Palette.graphite)
        for d = -L, L - DASH, DASH * 2 do
            love.graphics.rectangle("fill", d, -W, DASH, 1)
            love.graphics.rectangle("fill", d, W, DASH, 1)
        end
        love.graphics.rectangle("fill", -L, -W, 1, W * 2 + 1)
        love.graphics.rectangle("fill", L - 1, -W, 1, W * 2 + 1)

    elseif self.slap <= 0 then
        -- The ruler is off the page; what is left is the line it ruled, fading
        -- the way every other mark fades -- down a ramp, dithering out, never
        -- through an alpha that would invent a ninth colour.
        local def = self.def
        local f = self.age / def.life
        local ramp = def.ramp
        local dither = 0
        if f > def.fade then dither = (f - def.fade) / (1 - def.fade) end

        love.graphics.setColor(ramp[math.min(#ramp, math.floor(f * #ramp) + 1)])
        for d = -L, L - 2, 2 do
            if dither == 0 or util.hash01(d, self.seed, 31) > dither then
                love.graphics.rectangle("fill", d, 0, 2, 1)
            end
        end
    end

    love.graphics.pop()
end

-- The ruler itself, for the moment it is lying there. It is an object on the
-- paper rather than a mark in it, so it is drawn over the top of everything --
-- including whatever it has just flattened.
function Ruler:draw()
    if self.slap <= 0 then return end

    local L, W = self.length, self.def.width
    self:transform()

    -- Paper is the one colour that does not overprint -- it wipes what is under
    -- it instead of stacking with it -- so a ruler lying on the page really does
    -- cover the ruling underneath, exactly as the thing itself would.
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", -L, -W, L * 2, W * 2 + 1)

    -- Red for the first half of the slap, which is the whole of the impact.
    love.graphics.setColor(self.slap > SLAP * 0.5 and Palette.red or Palette.ink)
    love.graphics.rectangle("fill", -L, -W, L * 2, 1)
    love.graphics.rectangle("fill", -L, W, L * 2, 1)
    love.graphics.rectangle("fill", -L, -W, 1, W * 2 + 1)
    love.graphics.rectangle("fill", L - 1, -W, 1, W * 2 + 1)

    -- Graduations down one edge, every fourth one long. At this size they are
    -- what says "ruler" rather than "plank".
    love.graphics.setColor(Palette.slate)
    local n = 0
    for d = -L + TICK, L - TICK, TICK do
        n = n + 1
        love.graphics.rectangle("fill", d, -W + 1, 1, n % 4 == 0 and 5 or 3)
    end

    love.graphics.pop()
end

return Ruler
