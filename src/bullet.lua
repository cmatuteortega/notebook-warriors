local Sprites = require("src.sprites")

local Bullet = {}
Bullet.__index = Bullet

local SPEED = 110
local LIFETIME = 1.4

function Bullet.new(x, y, dx, dy, damage)
    return setmetatable({
        x = x, y = y,
        dx = dx, dy = dy,
        damage = damage,
        radius = 2,
        life = LIFETIME,
        dead = false,
    }, Bullet)
end

function Bullet:update(dt)
    self.x = self.x + self.dx * SPEED * dt
    self.y = self.y + self.dy * SPEED * dt
    self.life = self.life - dt
    if self.life <= 0 then self.dead = true end
end

function Bullet:draw()
    love.graphics.setColor(1, 1, 1)
    Sprites.bullet:draw(self.x, self.y)
end

return Bullet
