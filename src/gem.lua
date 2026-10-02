local Sprites = require("src.sprites")
local Sfx = require("src.sfx")
local util = require("src.util")

local Gem = {}
Gem.__index = Gem

-- Magnet range is handed in (src/upgrades.lua); pull speed is measured against
-- the fixed MAGNET_REF rather than that range, so a bigger magnet reaches
-- further without turning the last few pixels into a crawl.
local MAGNET_REF = 26
local MAGNET_MIN = 45
local MAGNET_SPEED = 110
local PICKUP_RANGE = 5

function Gem.new(x, y, xp)
    return setmetatable({
        x = x, y = y,
        xp = xp,
        bob = util.hash01(x, y, 3) * 2,
        dead = false,
    }, Gem)
end

function Gem:update(dt, player, range)
    local dx, dy, dist = util.normalize(player.x - self.x, player.y - self.y)

    if dist < PICKUP_RANGE then
        player:addXp(self.xp)
        -- One blip a gem: the gap on this sound's row (src/sfx.lua) drops
        -- what arrives inside it, so a dozen gems snapping in on one frame
        -- is one pickup you can hear, not twelve you cannot.
        Sfx.play("gem")
        self.dead = true
        return
    end

    if dist < range then
        local close = util.clamp(1 - dist / MAGNET_REF, 0, 1)
        local pull = MAGNET_MIN + (MAGNET_SPEED - MAGNET_MIN) * close
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
