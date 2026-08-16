-- The wet trail the eye boss drags behind it.
--
-- A puddle is the one hazard in the game the player makes no part of: every
-- other thing on the page is either yours or walking at you, and this is ground
-- that has stopped being safe. It is drawn in red over blush for exactly that
-- reason -- it belongs to the boss, and red is what belongs to the other side.
-- In sky over blue it was the one dangerous thing on the page wearing the
-- colour of the pen, the highlighter and every shot the player fires, so the
-- single piece of ground you must not stand on looked like something you had
-- put there yourself. It is dropped on a clock as the boss moves
-- (Game:updateEnemies), so a boss that stands still leaves one blot and a boss
-- chasing you across the page writes a wall of them behind itself -- which is
-- the whole tactic it has: it cannot corner you, so it takes the page away a
-- lane at a time.
--
-- It hurts by standing in it rather than by touching it, and it is the player's
-- own invulnerability window (Player:hurt) that decides how often -- exactly as
-- contact damage is rate-limited -- so wading through one is a hit and living in
-- one is a hit every 0.6s.
--
-- Nothing here is stored per pixel. The blot's ragged rim and the speckle inside
-- it are `util.hash01` of the offset and the puddle's seed, the way the pencil's
-- grain and the background's doodles are: the shape is a pure function, so a
-- puddle is five numbers however many pixels it covers.

local Palette = require("src.palette")
local util = require("src.util")

local Puddle = {}
Puddle.__index = Puddle

local FILL = 0.24      -- of the inside is left dry, so it reads as spatter
local DRY_FROM = 0.55  -- of its life at full wet; after that it dithers away
local RIM_DRY = 0.75   -- and the pooled rim gives up its red at

-- `damage` is handed in rather than read off `def`, because what a blot hurts
-- for is the boss's scaled number and not the one written in the table -- the
-- puddle keeps the numbers it was dropped with, the way a rocket keeps the ones
-- it was fired with.
function Puddle.new(x, y, def, damage, seed)
    return setmetatable({
        x = math.floor(x), y = math.floor(y),
        r = def.radius,
        damage = damage,
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

-- How wide the blot is on one row of it, rim included. Jittered per row off the
-- seed, so a puddle is a blot rather than a disc and no two of them are the
-- same blot.
function Puddle:widthAt(dy)
    local inside = self.r * self.r - dy * dy
    if inside < 0 then return -1 end
    return math.floor(math.sqrt(inside) + util.hash01(dy, self.seed, 5) * 1.8 - 0.4)
end

function Puddle:draw()
    local dried = self.age / self.life
    -- Dithering out rather than fading: alpha would blend paper and ink into a
    -- ninth colour and break the overprint lookup, so a drying puddle loses
    -- pixels instead of opacity, the same way every mark on the page fades.
    local drop = dried > DRY_FROM and (dried - DRY_FROM) / (1 - DRY_FROM) or 0

    love.graphics.setColor(Palette.blush)
    for dy = -self.r, self.r do
        local w = self:widthAt(dy)
        for dx = -w, w do
            local h = util.hash01(dx, dy, self.seed)
            if h > FILL + (1 - FILL) * drop then
                love.graphics.rectangle("fill", self.x + dx, self.y + dy, 1, 1)
            end
        end
    end

    -- The rim, where a spill pools and dries darkest. It is what makes the edge
    -- of the hazard readable at a glance, so it is the last thing to go: it
    -- holds red for three quarters of the life and then steps down to the same
    -- blush as the fill, the way the pen's line goes pale before it stops being
    -- a wall.
    love.graphics.setColor(dried < RIM_DRY and Palette.red or Palette.blush)
    for dy = -self.r, self.r do
        local w = self:widthAt(dy)
        if w >= 0 and util.hash01(dy, self.seed, 11) > drop then
            love.graphics.rectangle("fill", self.x - w, self.y + dy, 1, 1)
            love.graphics.rectangle("fill", self.x + w, self.y + dy, 1, 1)
        end
    end
end

return Puddle
