-- A blot of ground that has stopped being neutral: the eye boss's wet trail,
-- dropped on a clock as it moves (Game:updateEnemies), and a bomb's burn
-- (src/bomb.lua). Who it hurts is the owner's business, not this module's: the
-- boss's hurts the player (Game:updatePuddles), a bomb's the crowd. The two
-- colours come off the spec so a burn of yours is the same blot in the other
-- half of the palette. Nothing is stored per pixel -- the ragged rim and the
-- speckle are `util.hash01` of the offset and the seed, so a puddle is five
-- numbers however many pixels it covers.
--
-- The boss's blot hurts by standing in it, rate-limited by the player's own
-- invulnerability window (Player:hurt), so living in one is a hit every 0.6s. A
-- bomb's burn needs a clock of its own: nothing in the crowd has that window.

local Palette = require("src.palette")
local util = require("src.util")

local Puddle = {}
Puddle.__index = Puddle

local FILL = 0.24      -- of the inside is left dry, so it reads as spatter
local DRY_FROM = 0.55  -- of its life at full wet; after that it dithers away
local RIM_DRY = 0.75   -- and the pooled rim gives its darker colour up at

-- `damage` and `reach` are handed in rather than read off `def`: they are the
-- dropping enemy's scaled numbers (`reach` in Enemy.new), and the puddle keeps
-- what it was dropped with. `reach` defaults because most callers -- a bomb's
-- burn, an ordinary bulb -- have no opinion; `def.fill`/`def.rim` default to
-- the boss's colours.
function Puddle.new(x, y, def, damage, seed, reach)
    return setmetatable({
        x = math.floor(x), y = math.floor(y),
        r = def.radius * (reach or 1),
        damage = damage,
        fill = def.fill or Palette.blush,
        rim = def.rim or Palette.red,
        life = def.life,
        age = 0,
        seed = seed,
    }, Puddle)
end

function Puddle:update(dt)
    self.age = self.age + dt
    return self.age < self.life
end

function Puddle:covers(x, y)
    local dx, dy = x - self.x, y - self.y
    return dx * dx + dy * dy <= self.r * self.r
end

-- How wide the blot is on one row, rim included. Jittered per row off the seed,
-- so a puddle is a blot rather than a disc.
function Puddle:widthAt(dy)
    local inside = self.r * self.r - dy * dy
    if inside < 0 then return -1 end
    return math.floor(math.sqrt(inside) + util.hash01(dy, self.seed, 5) * 1.8 - 0.4)
end

function Puddle:draw()
    local dried = self.age / self.life
    -- Dithering out rather than fading: alpha would blend paper and ink into a
    -- ninth colour and break the overprint lookup.
    local drop = dried > DRY_FROM and (dried - DRY_FROM) / (1 - DRY_FROM) or 0

    love.graphics.setColor(self.fill)
    for dy = -self.r, self.r do
        local w = self:widthAt(dy)
        for dx = -w, w do
            local h = util.hash01(dx, dy, self.seed)
            if h > FILL + (1 - FILL) * drop then
                love.graphics.rectangle("fill", self.x + dx, self.y + dy, 1, 1)
            end
        end
    end

    -- The rim, where a spill pools and dries darkest, makes the edge readable,
    -- so it is the last thing to go: darker colour for three quarters of the
    -- life, then it steps down to the fill.
    love.graphics.setColor(dried < RIM_DRY and self.rim or self.fill)
    for dy = -self.r, self.r do
        local w = self:widthAt(dy)
        if w >= 0 and util.hash01(dy, self.seed, 11) > drop then
            love.graphics.rectangle("fill", self.x - w, self.y + dy, 1, 1)
            love.graphics.rectangle("fill", self.x + w, self.y + dy, 1, 1)
        end
    end
end

return Puddle
