local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Walls = require("src.walls")
local util = require("src.util")

local Enemy = {}
Enemy.__index = Enemy

local WALL_LOOK = 7  -- how far outside its clearance a wall starts to be felt
local SLIDE_HOLD = 0.9 -- how long a chosen way round a wall is kept to
local SLIP_CARRY = 0.5 -- how long footing stays lost after leaving the wax

-- How long out of the sun before what it has already soaked up is forgotten.
-- Comfortably longer than the sun's own burn tick, so a thing standing under
-- the disc goes on adding up between one burn and the next, and shorter than a
-- walk across the page, so crossing a lit corner twice in a run is not the same
-- as standing in one.
local SOAK_COOL = 1.2

-- Add a row here to add a monster; the spawner picks from this table by name.
-- A `shot` block makes it a shooter: it still walks at the player like the
-- rest, but every `every` seconds, if the player is within `range`, it spits a
-- pellet (Game:updateEnemyShots) that flies at `speed` and hits for `damage`.
Enemy.types = {
    blob  = { sprite = "blob",  hp = 4,  speed = 20, radius = 4, damage = 6,  xp = 1, shadow = 6 },
    bat   = { sprite = "bat",   hp = 2,  speed = 38, radius = 4, damage = 4,  xp = 1, shadow = 7 },
    skull = { sprite = "skull", hp = 12, speed = 15, radius = 5, damage = 12, xp = 3, shadow = 8 },
    eye   = { sprite = "eye",   hp = 14, speed = 9,  radius = 6, damage = 10, xp = 4, shadow = 9,
              shot = { range = 100, every = 2.4, speed = 40, damage = 8 } },
    -- The bloodshot eye is the same body with the pupil gone red: quicker on
    -- its feet (though still slower than a blob -- it is a shooter, not a
    -- chaser) and firing half again as often.
    redeye = { sprite = "redeye", hp = 14, speed = 16, radius = 6, damage = 10, xp = 6, shadow = 9,
              shot = { range = 100, every = 1.6, speed = 40, damage = 8 } },
}

function Enemy.new(kind, x, y)
    local def = Enemy.types[kind]
    return setmetatable({
        kind = kind,
        def = def,
        x = x, y = y,
        hp = def.hp,
        radius = def.radius,
        flash = 0,
        hitCooldown = 0,
        pushX = 0, pushY = 0,
        frozen = 0,
        burnT = 0, burnTick = 0, -- on fire: see Enemy:ignite / Game:updateBurning
        bob = util.hash01(x, y, 9) * 2, -- desync the walk cycles
        -- Which way it prefers to round an obstacle, so a crowd meeting a wall
        -- head-on splits and goes both ways instead of filing along it.
        side = util.hash01(x, y, 13) < 0.5 and -1 or 1,
        slideX = 0, slideY = 0, slideT = 0,
        -- Shooters spawn mid-beat, half to one-and-a-half periods from firing,
        -- so a ring of them arriving together doesn't volley in sync.
        shotT = def.shot and def.shot.every * (0.5 + util.hash01(x, y, 17)) or nil,
        headX = 0, headY = 0, -- the way it is actually going, vs the way it wants to
        slipT = 0, slipTurn = 0,
        -- Time stood under the sun, when it was last stood there, and whether
        -- it has had enough of it: see Enemy:sunburn.
        soak = 0, soakAt = 0, bleached = false,
    }, Enemy)
end

-- Steers along a wall rather than into it. Not real pathfinding, but it reads
-- as the same thing from outside: an enemy that meets a pen line slides along
-- it and rounds the end, and it costs one grid lookup instead of a search.
function Enemy:avoidWalls(dx, dy, walls)
    local near, clearance, nx, ny
    walls:each(self.x, self.y, function(seg)
        local cx, cy, d = Walls.closest(seg, self.x, self.y)
        local clear = seg.r + self.radius
        if d < clear + WALL_LOOK and (near == nil or d < near) then
            near, clearance = d, clear
            nx, ny = Walls.normalOut(seg, self.x - cx, self.y - cy)
        end
    end)
    if not near then return dx, dy end

    -- Walking along it, or away from it, is nobody's problem.
    local into = -(dx * nx + dy * ny)
    if into <= 0 then return dx, dy end

    local tx, ty = -ny, nx
    if self.slideT > 0 then
        -- Already going round: keep going that way. Re-deciding every frame
        -- would park it at the point on the wall nearest the player, sliding a
        -- pixel one way and a pixel back, and it would never reach an end.
        if tx * self.slideX + ty * self.slideY < 0 then tx, ty = -tx, -ty end
    else
        local along = dx * tx + dy * ty
        if math.abs(along) <= 0.05 then
            if self.side < 0 then tx, ty = -tx, -ty end
        elseif along < 0 then
            tx, ty = -tx, -ty
        end
    end
    self.slideX, self.slideY, self.slideT = tx, ty, SLIDE_HOLD

    -- Turn harder the closer it is and the more squarely it is heading in, so
    -- a glancing approach barely bends and a head-on one turns to a slide.
    local blend = into * util.clamp((clearance + WALL_LOOK - near) / WALL_LOOK, 0, 1)
    local rx, ry = util.normalize(dx + (tx - dx) * blend, dy + (ty - dy) * blend)
    if rx == 0 and ry == 0 then return tx, ty end
    return rx, ry
end

-- Steering alone is only a suggestion: the horde behind would shove enemies
-- straight through the line. This is the part that makes ink solid.
function Enemy:resolveWalls(walls)
    if self.frozen > 0 then return end
    walls:each(self.x, self.y, function(seg)
        local cx, cy, d = Walls.closest(seg, self.x, self.y)
        local clear = seg.r + self.radius
        if d < clear then
            local nx, ny = Walls.normalOut(seg, self.x - cx, self.y - cy)
            self.x, self.y = cx + nx * clear, cy + ny * clear
        end
    end)
end

function Enemy:update(dt, player, walls, slick)
    -- Glued: no chase, no drift, and any knockback it was carrying is dropped
    -- so it doesn't lurch the moment it comes unstuck. It can still be hit, and
    -- it still hurts the player who walks into it.
    if self.frozen > 0 then
        self.frozen = self.frozen - dt
        self.pushX, self.pushY = 0, 0
        self.flash = math.max(0, self.flash - dt)
        self.hitCooldown = math.max(0, self.hitCooldown - dt)
        return
    end

    self.slideT = math.max(0, self.slideT - dt)

    local dx, dy = util.normalize(player.x - self.x, player.y - self.y)
    if walls.count > 0 then
        dx, dy = self:avoidWalls(dx, dy, walls)
    end

    -- On wax it can't get purchase to change direction: the heading it arrived
    -- with wins, and it only bends towards where it wants to go. The footing
    -- stays lost for a moment after it leaves the band, so a thing that skids
    -- off the end carries on skidding instead of turning on a pixel -- without
    -- that, a 13px band crossed at speed would be over too fast to feel.
    -- Anywhere else the heading snaps, exactly as it always has.
    if slick then
        self.slipT, self.slipTurn = SLIP_CARRY, slick.turn
    elseif self.slipT > 0 then
        self.slipT = self.slipT - dt
    end

    if self.slipT > 0 then
        local k = 1 - math.exp(-self.slipTurn * dt)
        local hx = self.headX + (dx - self.headX) * k
        local hy = self.headY + (dy - self.headY) * k
        local nx, ny = util.normalize(hx, hy)
        if nx ~= 0 or ny ~= 0 then dx, dy = nx, ny end
    end
    self.headX, self.headY = dx, dy

    self.x = self.x + dx * self.def.speed * dt
    self.y = self.y + dy * self.def.speed * dt

    -- Knockback rides on top of the chase and bleeds off exponentially.
    if self.pushX ~= 0 or self.pushY ~= 0 then
        self.x = self.x + self.pushX * dt
        self.y = self.y + self.pushY * dt
        local decay = math.exp(-9 * dt)
        self.pushX, self.pushY = self.pushX * decay, self.pushY * decay
        if math.abs(self.pushX) + math.abs(self.pushY) < 1 then
            self.pushX, self.pushY = 0, 0
        end
    end

    self.bob = (self.bob + dt * 7) % 2
    self.flash = math.max(0, self.flash - dt)
    self.hitCooldown = math.max(0, self.hitCooldown - dt)
end

function Enemy:hurt(amount)
    -- Glue-stuck things take deeper cuts -- a gluestick level. Everything that
    -- deals damage arrives through this one door, so the multiplier rides on
    -- the enemy rather than being known to any of the dozen things that hit.
    if self.glue and self.frozen > 0 and self.glue.soften then
        amount = amount * self.glue.soften
    end
    self.hp = self.hp - amount
    self.flash = 0.08
    return self.hp <= 0
end

function Enemy:knockback(nx, ny, force)
    self.pushX = self.pushX + nx * force
    self.pushY = self.pushY + ny * force
end

-- Sent flying hard enough to matter -- the rubber's last level. A launch gets
-- a fresh hit list, so an enemy rubbed at again can bowl over the same thing
-- again; what counts as still flying is Game:updateRams' threshold on the push
-- speed, which is also what quietly ends the state -- a glued enemy drops its
-- push and stops being a projectile the same frame.
function Enemy:launch(ram)
    self.ram = { damage = ram.damage, hit = {} }
end

-- Set alight -- the highlighter's last level (src/upgrades.lua). Touching the
-- ink again refreshes the burn rather than stacking it, so standing on the band
-- holds it at full and leaving starts the clock. The first tick lands at once:
-- catching fire is felt the moment it happens, not a beat later. The block is
-- kept by reference, the way a rocket keeps the numbers it was fired with --
-- an upgrade mid-burn changes the next fire, not this one.
function Enemy:ignite(burn)
    if self.burnT <= 0 then self.burnTick = 0 end
    self.burnT = math.max(self.burnT, burn.time)
    self.burn = burn
end

-- Left out in the sun (src/sun.lua). Exposure is *counted* rather than timed
-- from a start: a thing that walks in and out of the disc is judged on the total
-- it has stood under it, and what it soaked up is forgotten again once it has
-- been out of the light for SOAK_COOL. That is what makes this "stayed under too
-- long" rather than "was under it once", and it is why the sun does not need to
-- keep a list of who is in it.
--
-- Past the limit it is bleached for good and carries a grey ghost of its own
-- outline for the rest of its life (Enemy:draw) -- the mark is the only thing
-- the sun tells you about what it did, since nothing under a solid disc can be
-- seen while it is happening. Returns true the one time it crosses, so the
-- caller can spend a splat on the moment.
function Enemy:sunburn(amount, limit, now)
    if now - self.soakAt > SOAK_COOL then self.soak = 0 end
    self.soakAt = now
    if self.bleached then return false end

    self.soak = self.soak + amount
    self.bleached = self.soak >= limit
    return self.bleached
end

-- Returns true only the first time, so the caller can spend a splat on it.
-- `glue` is the tool doing the sticking, when a tool is: the enemy carries it
-- for as long as it is held, which is how the gluestick's upper levels --
-- deeper cuts while stuck (Enemy:hurt), the tear on the way loose
-- (Game:updateGlue) -- know their victim without the tool keeping a list.
-- A pin's or a staple's hold passes nothing and grants nothing.
function Enemy:freeze(duration, glue)
    local wasFree = self.frozen <= 0
    self.frozen = math.max(self.frozen, duration)
    if glue then self.glue = glue end
    return wasFree
end

function Enemy:draw()
    local sprite = Sprites.enemies[self.def.sprite]
    local stuck = self.frozen > 0
    -- Stuck things stop bobbing, and the shadow turns into a smear of glue.
    local y = (not stuck and self.bob >= 1) and self.y - 1 or self.y

    love.graphics.setColor(stuck and Palette.sky or Palette.graphite)
    local shadow = self.def.shadow + (stuck and 2 or 0)
    love.graphics.rectangle("fill",
        math.floor(self.x) - math.floor(shadow / 2),
        math.floor(self.y) + math.floor(sprite.h / 2) - 1,
        shadow, stuck and 2 or 1)

    -- Sun-bleached: its own silhouette in graphite, one pixel out all the way
    -- round, drawn under the body rather than over it. Over it would be a thing
    -- you can no longer identify, and what this has to say is "that one has been
    -- stood in the sun" about a blob that still reads as a blob. Four offset
    -- masks rather than an authored outline, since the enemy it is outlining may
    -- be any sprite in the game.
    if self.bleached then
        love.graphics.setColor(Palette.graphite)
        sprite:drawMask(self.x - 1, y)
        sprite:drawMask(self.x + 1, y)
        sprite:drawMask(self.x, y - 1)
        sprite:drawMask(self.x, y + 1)
    end

    if self.flash > 0 then
        -- Flat blush silhouette on hit: cheap, readable, still on palette.
        love.graphics.setColor(Palette.blush)
        sprite:drawMask(self.x, y)
    else
        love.graphics.setColor(1, 1, 1)
        sprite:draw(self.x, y)
    end
end

return Enemy
