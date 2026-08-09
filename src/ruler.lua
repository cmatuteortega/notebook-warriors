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

local Palette = require("src.palette")
local util = require("src.util")

local Ruler = {}
Ruler.__index = Ruler

local SLAP = 0.14   -- how long the ruler itself lies on the page after it lands
local DEAD = 4      -- pointer this close to the pivot leaves the angle alone
local DASH = 3      -- pencil dash marking out where it will land
local TICK = 8      -- pixels between graduations

function Ruler.new(def, x, y)
    return setmetatable({
        def = def,
        x = x, y = y,      -- the pivot: the player
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

-- Both ends of it. A ruler is a line through you rather than a beam out of you,
-- so it reaches the same distance behind as in front.
function Ruler:ends()
    local L = self.def.length
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

    -- Graphite jumping off the page along its whole length, so the slap reads
    -- as a slap rather than a line appearing.
    for i = 0, 4 do
        local t = i / 4
        game.particles:burst(ax + (bx - ax) * t, ay + (by - ay) * t, 2, Palette.graphite)
    end

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if util.distToSegment(e.x, e.y, ax, ay, bx, by) < def.width + e.radius then
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
    local L, W = self.def.length, self.def.width
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

    local L, W = self.def.length, self.def.width
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
