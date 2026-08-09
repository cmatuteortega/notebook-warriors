local Sprites = require("src.sprites")
local util = require("src.util")

local Gem = {}
Gem.__index = Gem

local MAGNET_RANGE = 26
local MAGNET_SPEED = 90
local PICKUP_RANGE = 5

function Gem.new(x, y, xp)
    return setmetatable({
        x = x, y = y,
        xp = xp,
        bob = util.hash01(x, y, 3) * 2,
        dead = false,
    }, Gem)
end

function Gem:update(dt, player)
    local dx, dy, dist = util.normalize(player.x - self.x, player.y - self.y)

    if dist < PICKUP_RANGE then
        player:addXp(self.xp)
        self.dead = true
        return
    end

    if dist < MAGNET_RANGE then
        -- Accelerate as it closes, so pickups feel like they snap in.
        local pull = MAGNET_SPEED * (1 - dist / MAGNET_RANGE) + 20
        self.x = self.x + dx * pull * dt
        self.y = self.y + dy * pull * dt
    else
        self.bob = (self.bob + dt * 4) % 2
    end
end

function Gem:draw()
    love.graphics.setColor(1, 1, 1)
    Sprites.gem:draw(self.x, self.y - (self.bob >= 1 and 1 or 0))
end

return Gem
