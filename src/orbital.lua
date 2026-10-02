-- Stars orbiting the player: passive, attached to the hero, so it carries an
-- angle and no position. Stats come from the upgrade line (src/upgrades.lua).

local Palette = require("src.palette")
local Sprites = require("src.sprites")

local Orbital = {}
Orbital.__index = Orbital

-- The star sprite is 7 across, so this is its own edge. Fixed by the art's
-- size: a drawn star changes how it looks, never what it reaches.
local HIT_R = 4
local TWO_PI = math.pi * 2

function Orbital.new()
    return setmetatable({
        def = nil,
        angle = 0,
        breath = 0,
        -- enemy -> time last cut, so one pass can't shave the same blob twice.
        -- Weak keys: this outlives thousands of kills, so the dead fall out.
        hit = setmetatable({}, { __mode = "k" }),
    }, Orbital)
end

function Orbital:configure(def)
    self.def = def
end

-- Constant until the breathe upgrade is taken.
function Orbital:reach()
    local def = self.def
    if def.breathe <= 0 then return def.radius end
    return def.radius + math.sin(self.breath) * def.breathe
end

-- Where the stars are this instant, spread evenly round the ring.
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

    -- Graphite (passiveDamage) sharpens passives; the global multiplier is
    -- on top.
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
