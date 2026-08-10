-- Stars going round you.
--
-- The first passive weapon: a doodle that fights while your hands are busy
-- drawing, and one you drew yourself -- taking the first level of the line hands
-- you the board (src/design.lua, src/studio.lua). It is not a mark on the page
-- and not a thing standing on it -- it is attached to you, so it needs no
-- position of its own, only an angle.
--
-- Everything about it comes out of the stats block the upgrade line built
-- (src/upgrades.lua): how many stars, how far out, how fast round, how hard,
-- and how far the ring swells and shrinks while it turns. The instance survives
-- being reconfigured, so taking the next level speeds the orbit up rather than
-- restarting it from wherever the first star happened to be.
--
-- The hit test asks the run's spatial hash rather than walking the horde, the
-- way a bullet does: a star is small enough that the nine cells around it are
-- the whole of what it can reach.

local Palette = require("src.palette")
local Sprites = require("src.sprites")

local Orbital = {}
Orbital.__index = Orbital

-- The star sprite is 7 across, so this is its own edge. A design is fixed at
-- the size of the art it starts from, which is what keeps this honest: drawing
-- your own star changes what it looks like and never what it reaches.
local HIT_R = 4
local TWO_PI = math.pi * 2

function Orbital.new()
    return setmetatable({
        def = nil,
        angle = 0,
        breath = 0,
        -- enemy -> the time it was last cut, so a star sweeping through a crowd
        -- can't shave the same blob twice in one pass. Weak keys: a run kills
        -- thousands of things and this table outlives every one of them, so the
        -- dead have to be able to fall out of it on their own.
        hit = setmetatable({}, { __mode = "k" }),
    }, Orbital)
end

function Orbital:configure(def)
    self.def = def
end

-- The ring only breathes once the upgrade that makes it breathe is taken, and
-- until then this is a constant.
function Orbital:reach()
    local def = self.def
    if def.breathe <= 0 then return def.radius end
    return def.radius + math.sin(self.breath) * def.breathe
end

-- Where the stars are this instant, spread evenly round the ring: one star, or
-- two opposite each other, or three at the corners of a triangle.
function Orbital:each(px, py, fn)
    local r = self:reach()
    local step = TWO_PI / self.def.count

    for i = 0, self.def.count - 1 do
        local a = self.angle + i * step
        fn(px + math.cos(a) * r, py + math.sin(a) * r)
    end
end

function Orbital:update(dt, game, grid)
    local def = self.def
    local stats = game.loadout.stats

    self.angle = (self.angle + def.rate * dt) % TWO_PI
    self.breath = (self.breath + def.breatheRate * dt) % TWO_PI

    -- A passive weapon is what graphite sharpens, and the global multiplier
    -- lands on everything.
    local damage = def.damage * stats.passiveDamage * stats.damage

    self:each(game.player.x, game.player.y, function(x, y)
        game:eachNear(grid, x, y, function(e)
            local dx, dy = e.x - x, e.y - y
            local reach = HIT_R + e.radius
            if dx * dx + dy * dy >= reach * reach then return end

            local last = self.hit[e]
            if last and game.time - last < def.rehit then return end
            self.hit[e] = game.time

            game.particles:burst(x, y, 2, Palette.red)
            if e:hurt(damage) then
                game:killEnemyAt(e)
            end
        end)
    end)
end

function Orbital:draw(game)
    love.graphics.setColor(1, 1, 1)
    self:each(game.player.x, game.player.y, function(x, y)
        Sprites.star:draw(x, y)
    end)
end

return Orbital
