-- Single-pixel ink specks, sprayed when something dies or gets hit.
--
-- Two shapes of them, and the difference is only in how they set off: a burst
-- leaves a point in every direction, a crumb is rubbed off the side of a tip
-- that is moving. After that they are the same thing -- one pixel, some drag,
-- and gone.

local Palette = require("src.palette")

local Particles = {}
Particles.__index = Particles

local DRAG = 3   -- default; a crumb brakes much harder than a speck

function Particles.new()
    return setmetatable({ list = {} }, Particles)
end

function Particles:burst(x, y, count, color)
    for _ = 1, count do
        local a = love.math.random() * math.pi * 2
        local speed = 18 + love.math.random() * 34
        self.list[#self.list + 1] = {
            x = x, y = y,
            dx = math.cos(a) * speed,
            dy = math.sin(a) * speed,
            life = 0.25 + love.math.random() * 0.3,
            color = color or Palette.slate,
        }
    end
end

-- One eraser crumb, shed at (x, y) off a tip of `radius` travelling along the
-- unit vector (dx, dy). It leaves across the rub -- a side picked per crumb,
-- which is what makes a sweep spray out of both edges at once -- with enough of
-- the rub's own direction in it to look carried along rather than flicked off.
-- Hard drag and a short life: a crumb skitters a few pixels clear of the tip,
-- stops, and is gone before you have finished the stroke.
function Particles:crumb(x, y, dx, dy, radius, color)
    local side = love.math.random() < 0.5 and -1 or 1
    local px, py = -dy * side, dx * side
    local out = 34 + love.math.random() * 46
    local along = 12 + love.math.random() * 30
    self.list[#self.list + 1] = {
        -- Born at the rim rather than the centre, so the spray is as wide as
        -- the thing shedding it.
        x = x + px * radius * 0.7,
        y = y + py * radius * 0.7,
        dx = px * out + dx * along,
        dy = py * out + dy * along,
        drag = 9,
        life = 0.2 + love.math.random() * 0.25,
        color = color or Palette.graphite,
    }
end

-- The flash of a critical hit. An even eight-spoke ring rather than a random
-- spray, alternating the darkest ink with red, faster than anything else here
-- and braking hard: it reads as a starburst stamped on the moment, which is
-- what separates "that hit landed deep" from the ordinary two-pixel spatter
-- every hit throws.
function Particles:crit(x, y)
    for i = 1, 8 do
        local a = (i - 1) / 8 * math.pi * 2
        local speed = 55 + love.math.random() * 25
        self.list[#self.list + 1] = {
            x = x, y = y,
            dx = math.cos(a) * speed,
            dy = math.sin(a) * speed,
            drag = 6,
            life = 0.18 + love.math.random() * 0.15,
            color = i % 2 == 0 and Palette.ink or Palette.red,
        }
    end
end

-- A flame lick off something burning. Fire is the one thing here that rises:
-- born just off the point it comes from and drifting up rather than out, red
-- with the odd blush ember, gone in under half a second. Little drag, because
-- what a crumb does -- skitter and stop -- is exactly what fire doesn't.
function Particles:flame(x, y)
    self.list[#self.list + 1] = {
        x = x + love.math.random(-2, 2),
        y = y - 1 - love.math.random(0, 2),
        dx = (love.math.random() - 0.5) * 16,
        dy = -(14 + love.math.random() * 24),
        drag = 2,
        life = 0.2 + love.math.random() * 0.25,
        color = love.math.random() < 0.7 and Palette.red or Palette.blush,
    }
end

function Particles:update(dt)
    for i = #self.list, 1, -1 do
        local p = self.list[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        -- Clamped, or a long frame turns heavy drag into a bounce backwards.
        local keep = math.max(0, 1 - (p.drag or DRAG) * dt)
        p.dx = p.dx * keep
        p.dy = p.dy * keep
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.list, i)
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.list) do
        love.graphics.setColor(p.color)
        love.graphics.rectangle("fill", math.floor(p.x), math.floor(p.y), 1, 1)
    end
end

return Particles
