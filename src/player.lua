local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Input = require("src.input")
local util = require("src.util")

local Player = {}
Player.__index = Player

local SPEED = 58
local INVULN_TIME = 0.6

function Player.new(x, y)
    return setmetatable({
        x = x, y = y,
        -- Kept in proportion to the sprite the studio hands over, which is a
        -- good deal bigger than a monster: contact lands about where the drawing
        -- does rather than a few pixels inside it.
        radius = 6,
        flip = false,
        moving = false,
        bob = 0,
        hp = 100,
        maxHp = 100,
        invuln = 0,

        level = 1,
        xp = 0,
        xpNext = 5,

        -- Auto-attack: fires at the nearest enemy in range, hands-free.
        fireTimer = 0,
        fireRate = 0.55,
        damage = 3,
        range = 96,

        slick = false,
        skid = 0, -- spacing on the wax flicked up while running
    }, Player)
end

function Player:update(dt, game)
    -- Keyboard or invisible touch stick; the stick is analogue, so this vector
    -- can be shorter than 1 and the player walks proportionally slower.
    local dx, dy = Input.movement()

    -- Wax underfoot: you run along your own crayon lane. The enemies chasing
    -- you are on the same surface and can't corner on it, which is the point.
    local slick = game.hasSlick and game:slickAt(self.x, self.y) or nil
    self.slick = slick ~= nil
    local speed = slick and SPEED * slick.boost or SPEED

    self.x = self.x + dx * speed * dt
    self.y = self.y + dy * speed * dt

    self.moving = dx ~= 0 or dy ~= 0

    -- Flakes kicked up off the wax, so the speed reads as speed.
    if self.slick and self.moving then
        self.skid = self.skid - speed * dt
        if self.skid <= 0 then
            self.skid = 7
            game.particles:burst(self.x - dx * 3, self.y + 4 - dy * 3, 1, Palette.blue)
        end
    end
    if dx < 0 then self.flip = true elseif dx > 0 then self.flip = false end

    -- One-pixel walk bounce, the whole animation budget of a doodle.
    self.bob = self.moving and (self.bob + dt * 9) % 2 or 0

    self.invuln = math.max(0, self.invuln - dt)

    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 then
        if self:fire(game) then
            self.fireTimer = self.fireRate
        else
            self.fireTimer = 0.05 -- nothing in range; check again shortly
        end
    end
end

function Player:fire(game)
    local best, bestDist
    for _, e in ipairs(game.enemies) do
        local d = util.len(e.x - self.x, e.y - self.y)
        if d <= self.range and (not bestDist or d < bestDist) then
            best, bestDist = e, d
        end
    end
    if not best then return false end

    local dx, dy = util.normalize(best.x - self.x, best.y - self.y)
    game:spawnBullet(self.x, self.y - 1, dx, dy, self.damage)
    return true
end

function Player:hurt(amount)
    if self.invuln > 0 then return false end
    self.hp = math.max(0, self.hp - amount)
    self.invuln = INVULN_TIME
    return true
end

function Player:addXp(amount)
    self.xp = self.xp + amount
    while self.xp >= self.xpNext do
        self.xp = self.xp - self.xpNext
        self.level = self.level + 1
        self.xpNext = math.floor(self.xpNext * 1.45) + 2
        -- No upgrade menu yet: levelling just sharpens the auto-attack a little.
        self.fireRate = math.max(0.12, self.fireRate * 0.94)
        self.hp = math.min(self.maxHp, self.hp + 5)
    end
end

function Player:draw()
    -- Blink while invulnerable.
    if self.invuln > 0 and math.floor(self.invuln * 20) % 2 == 1 then return end

    local sprite = Sprites.player
    local y = self.y - (self.bob >= 1 and 1 or 0)

    Sprites.shadow(sprite, self.x, self.y)

    love.graphics.setColor(1, 1, 1)
    sprite:draw(self.x, y, self.flip)
end

return Player
