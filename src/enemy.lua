local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Walls = require("src.walls")
local pixelart = require("src.pixelart")
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

-- The boss's pupil: a disc slid across the iris towards the player rather than
-- a pixel of the sprite, which is why the art has no pupil in it. The eye is the
-- one enemy in the game whose sprite says which way it is facing, and a boss you
-- are running away from ought to be watching you do it.
local PUPIL_R = 4
local PUPIL_SLIDE = 5 -- how far off centre it may sit: the iris is 19 across
                      -- and the pupil is 9, so at 5 it still clears the rim
local PUPIL_TURN = 6  -- how fast it swings across, in fractions per second --
                      -- an eye tracks smoothly, it does not snap

-- Add a row here to add a monster; the spawner picks from this table by name.
-- A `shot` block makes it a shooter: it still walks at the player like the
-- rest, but every `every` seconds, if the player is within `range`, it spits a
-- pellet (Game:updateEnemyShots) that flies at `speed` and hits for `damage`.
-- `spread` and `arc` on that block make it a volley: `spread` pellets fanned
-- across `arc` radians instead of the one straight down the line.
--
-- Five fields turn a row into a boss, and none of them is a special case
-- anywhere else: `boss` (never despawns, never shoved out of the way by the
-- crowd, and ends the run when it dies), `trail` (a wet blot dropped behind it
-- as it walks, src/puddle.lua), `tears` (the same wet thrown rather than walked,
-- three ways -- Game:updateTears), and `knock`/`hold` -- what a shove and a
-- glueing are worth against it, both 1 for everything ordinary.
--
-- The box the fight happens in is not one of them, and deliberately: an arena is
-- a fact about the *fight* rather than about the monster, so the spawner opens it
-- when it sends the boss (src/arena.lua) and nothing in this table knows.
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
    -- The eye boss, which is the eye at four times across and the same idea
    -- taken seriously: it walks at you slower than you can walk away, it fires
    -- a fan rather than a pellet, and it wets the page behind itself so the
    -- ground you retreated over stops being ground. Every one of those is a
    -- thing you answer by moving, which is why it is slow -- a boss you cannot
    -- outrun would just be a big blob.
    --
    -- The hp is the one number here set by measurement rather than by design.
    -- A run holding every passive weapon at its last level puts about 30 damage
    -- a second into a *single* target -- far less than it does into a crowd,
    -- since most of what a build sells is area -- so 900, scaled to 1260 by the
    -- time the first one walks on (Game:enemyScale), is a fight of half a minute
    -- for a strong run and rather longer for one that drafted wide. That is the
    -- number to move if the fight is the wrong length; everything else about the
    -- boss is a design decision.
    bosseye = { sprite = "bosseye", hp = 900, speed = 26, radius = 20, damage = 20,
              xp = 250, shadow = 34, boss = true, pupil = true, knock = 0.06, hold = 0.3,
              shot = { range = 190, every = 2.6, speed = 46, damage = 12, hit = 4,
                       spread = 5, arc = 1.05, sprite = "bossShot" },
              trail = { every = 0.5, gap = 9, radius = 12, life = 7, damage = 6 },
              -- The eye cries, and where a tear lands the page is wet.
              --
              -- The trail above is the boss denying you the ground it walked
              -- over, which is ground you chose to give it. The tears are the
              -- half of the same idea it does not have to walk to: they land
              -- where it is not, so the arena fills up from the middle as well
              -- as behind it, and a corner you were saving stops being a plan.
              --
              -- Three deliveries off one projectile, which is what keeps the
              -- fight varied without teaching three separate things. A tear is a
              -- tear wherever it came from -- it hurts if it hits you on the way
              -- and it puddles where it stops -- so all any of these change is
              -- *where* a handful of them land.
              --
              -- The puddle a tear leaves is deliberately smaller and shorter
              -- than the one the boss drags behind it: the trail is the price of
              -- letting it walk, and should be worse than weather.
              tears = { speed = 74, damage = 8, hit = 3, sprite = "tear",
                        puddle = { radius = 10, life = 5.5, damage = 6 },
                        -- The weather. A few at a time, anywhere in the box,
                        -- landing near or far -- the one attack that is not
                        -- aimed at you at all, so it is the one that makes
                        -- standing still bad on its own account.
                        scatter = { every = 3.2, count = 3, near = 34, far = 130 },
                        -- The lane. Fired straight down the line to the player
                        -- and landing at rising distances, so what it draws is a
                        -- wall across the way you were about to go rather than a
                        -- shot at where you are. Aimed, but at the ground.
                        lane = { every = 7.5, count = 5, from = 26, step = 24 },
                        -- The two turns. Fired once each as the fight passes two
                        -- thirds and one third of the eye's health, a full ring
                        -- of tears thrown out around it -- so the moment the bar
                        -- says the fight is going your way, the floor answers.
                        -- Thresholds rather than a clock, because what they are
                        -- for is marking progress you earned.
                        ring = { at = { 0.66, 0.33 }, count = 14, radius = 50 } } },
}

-- `scale` is how much harder the run has got since it started (Game:enemyScale)
-- and it is baked in *here*, once, rather than read off the run wherever damage
-- is dealt. That is what makes a monster keep the numbers it walked on with: the
-- horde standing on the page when a cycle ends is the horde that cycle spawned,
-- and nothing already alive gets tougher because the clock rolled over. It is
-- also why hp, damage and xp live on the enemy while everything else stays on
-- the shared `def` -- those three are the only ones a scale touches.
function Enemy.new(kind, x, y, scale)
    local def = Enemy.types[kind]
    local hpMul = scale and scale.hp or 1
    local dmgMul = scale and scale.damage or 1
    local hp = def.hp * hpMul

    return setmetatable({
        kind = kind,
        def = def,
        x = x, y = y,
        hp = hp,
        maxHp = hp,
        damage = def.damage * dmgMul,
        shotDamage = def.shot and def.shot.damage * dmgMul or nil,
        trailDamage = def.trail and def.trail.damage * dmgMul or nil,
        -- A tear hits for less than a pellet does and puddles for what a puddle
        -- is worth, and both are scaled here with everything else -- so the
        -- three numbers stay three numbers. Reading the fan's damage for a tear
        -- would have worked today (the trail and a tear's puddle happen to both
        -- be 6) and quietly stopped working the moment anyone tuned one of them.
        tearDamage = def.tears and def.tears.damage * dmgMul or nil,
        tearWet = def.tears and def.tears.puddle.damage * dmgMul or nil,
        -- Worth what it costs to kill, which is why this rides the *hp*
        -- multiplier and not the damage one. A cycle-two blob takes 40% longer
        -- to put down, so a run clears 40% fewer of them a minute; paying the
        -- written 1xp for it would mean the horde quietly paid less every cycle
        -- while the xp ladder went on asking for more (`XP_RISE` in
        -- src/player.lua), and a long run would stop levelling somewhere in
        -- cycle two however well it was going. Tying the two together makes xp a
        -- second a flat thing across a cycle boundary rather than a falling one:
        -- the ladder still slows down as it climbs, which it should, but it
        -- slows down because levels cost more and never because the page has
        -- quietly stopped paying.
        --
        -- It leaves the value fractional, which nothing minds -- xp is only ever
        -- read as a fraction of the next level (Player:addXp) and is never
        -- written down for anyone to see.
        xp = def.xp * hpMul,
        radius = def.radius,
        flash = 0,
        hitCooldown = 0,
        -- What it has taken since the page last said so, and the moment that
        -- reading opened (Game:spendHits). Kept here rather than at the dozen
        -- places that deal damage for the same reason the glue's multiplier is:
        -- everything arrives through Enemy:hurt, so there is exactly one place
        -- that has to count. `tookAt` is 0 for "nothing pending" -- the sweep
        -- stamps it the first frame it finds something, off the run clock, which
        -- is a clock Enemy:hurt has no business being handed.
        took = 0, tookAt = 0,
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
        -- The trail clock, and where the last blot went: a boss standing still
        -- drops one puddle and stops, since the clock only pays out once it has
        -- walked clear of what it last put down (Game:updateEnemies).
        trailT = def.trail and def.trail.every or nil,
        -- The two tear clocks, and how many of the health thresholds have been
        -- passed. `rings` counts rather than flags because the thresholds are
        -- taken in order and never come back -- healing is not a thing in this
        -- game, so "how many have gone" is the whole state a ring needs.
        scatterT = def.tears and def.tears.scatter.every or nil,
        laneT = def.tears and def.tears.lane.every or nil,
        rings = 0,
        headX = 0, headY = 0, -- the way it is actually going, vs the way it wants to
        -- Where the pupil is looking, as a fraction of how far it may slide.
        -- Chased rather than set, so the eye swings round to you (Enemy:draw).
        lookX = 0, lookY = 0,
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
    -- The eye follows you whatever else is happening to it -- glued, frozen,
    -- stood still -- because that is the one thing an eye does. Chased towards
    -- the direction of the player rather than set to it, so it swings.
    if self.def.pupil then
        local dx, dy = util.normalize(player.x - self.x, player.y - self.y)
        local k = 1 - math.exp(-PUPIL_TURN * dt)
        self.lookX = self.lookX + (dx - self.lookX) * k
        self.lookY = self.lookY + (dy - self.lookY) * k
    end

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
    -- Added up rather than announced. Two weapons landing on the same enemy in
    -- the same frame are one thing that happened to it, and the page says so
    -- with one number; Game:spendHits is what decides when the total has stood
    -- still long enough to be worth reading.
    self.took = self.took + amount
    return self.hp <= 0
end

-- `knock` on the row is what a shove is worth against this thing, and it exists
-- for exactly one reason: a boss that can be bowled across the page by a pin is
-- a boss you never have to look at. It rides here rather than at the dozen
-- places that shove, the same way the glue's damage multiplier rides on
-- Enemy:hurt.
function Enemy:knockback(nx, ny, force)
    force = force * (self.def.knock or 1)
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
    -- `hold` is the same bargain `knock` makes: a boss glued for the full four
    -- seconds is a boss that is not a fight, so it shrugs most of it off. It is
    -- never zero -- a tool that visibly does nothing is worse than one that does
    -- a little -- and it is scaled rather than capped, so every level of the
    -- gluestick line still buys something against it.
    self.frozen = math.max(self.frozen, duration * (self.def.hold or 1))
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

    -- The pupil, over the iris the art left empty. A disc rather than a sprite
    -- because it is drawn at a different place every frame and there is nothing
    -- to author: `pixelart.circleFill` plots whole pixels on the same grid as
    -- everything else, which is the rule a rotated sprite would break. It
    -- flashes with the body, since a white body with a black pupil still in it
    -- would read as the hit landing on something else.
    if self.def.pupil then
        love.graphics.setColor(self.flash > 0 and Palette.blush or Palette.ink)
        pixelart.circleFill(
            self.x + self.lookX * PUPIL_SLIDE,
            y + self.lookY * PUPIL_SLIDE, PUPIL_R)
    end
end

return Enemy
