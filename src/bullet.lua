-- What SHOT sends, in the air (src/shot.lua): one pellet per beat of that
-- weapon's clock, flying straight until it hits something or times out.
-- Drawn by the player (src/design.lua, Sprites.SHOT); radius 2 is the
-- drawing's half-width on the fixed 5x5 board, so a shot drawn out to the
-- corners hits exactly where the small one does. Speed is handed in and kept
-- on the bullet, so a level taken mid-flight lands on the next pellet rather
-- than speeding this one up.

local Sprites = require("src.sprites")

local Bullet = {}
Bullet.__index = Bullet

-- Floor under a bad options file only: nothing fires a pellet without a block,
-- and a shot's speed is set by the level tables in src/upgrades.lua.
local SPEED = 110

-- Deliberately not what the line sells: this only has to outlast the block's
-- `range`, and the slowest shot in the catalogue covers its reach inside it.
local LIFETIME = 1.4

function Bullet.new(x, y, dx, dy, damage, speed)
    return setmetatable({
        x = x, y = y,
        dx = dx, dy = dy,
        damage = damage,
        speed = speed or SPEED,
        radius = 2, -- the drawing's half-width; see the header

        life = LIFETIME,
        dead = false,
    }, Bullet)
end

function Bullet:update(dt)
    self.x = self.x + self.dx * self.speed * dt
    self.y = self.y + self.dy * self.speed * dt
    self.life = self.life - dt
    if self.life <= 0 then self.dead = true end
end

function Bullet:draw()
    love.graphics.setColor(1, 1, 1)
    Sprites.bullet:draw(self.x, self.y)
end

return Bullet
