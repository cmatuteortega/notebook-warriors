local Sprites = require("src.sprites")
local util = require("src.util")

local Gem = {}
Gem.__index = Gem

-- How far a gem comes from is the magnet upgrade's business (src/upgrades.lua)
-- and is passed in. How fast it comes is not: the pull is measured against a
-- fixed distance rather than against the range, so a bigger magnet reaches
-- further without turning the last few pixels into a crawl -- a gem hauled in
-- from across the page sets off at MAGNET_MIN and only snaps once it is inside
-- the distance the magnet had before any upgrade.
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
        self.dead = true
        return
    end

    if dist < range then
        -- Accelerate as it closes, so pickups feel like they snap in.
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
