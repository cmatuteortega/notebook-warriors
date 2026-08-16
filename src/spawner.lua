-- Drops enemies on a ring just outside the camera so they always walk on from
-- offscreen, and slowly turns up the pressure as the run goes on.
--
-- A run is a **cycle** repeated: ten minutes of horde, then the eye boss, and
-- the horde stops arriving while it is on the page. Killing it wins the run
-- (src/win.lua); carrying on hands the spawner another cycle, harder than the
-- last. The spawner owns that clock because it already owns every other one --
-- what phase the run is in is a fact about what is being spawned.

local util = require("src.util")

local Spawner = {}
Spawner.__index = Spawner

local SPAWN_RADIUS = 200
local SPAWN_CLEARANCE = 24 -- past the corner of the screen, so nothing appears
                           -- out of thin air on a wide one
local MAX_ENEMIES = 260

-- The horde has a floor as well as a ceiling. The floor rises with the
-- difficulty clock at FLOOR_RATE enemies per scaled second, and whenever the
-- horde is under it the spawner refills immediately instead of waiting for the
-- next wave -- so a build that clears the screen is answered with more horde,
-- not a quiet spell, and kill speed buys xp rather than calm. Topped up REFILL
-- at a time, every frame, so a cleared page pours back in over a second or so
-- instead of materialising all at once.
local FLOOR_RATE = 0.6
local REFILL = 3

-- How long a cycle of horde runs before the boss walks on. Ten minutes of real
-- time rather than of the difficulty clock, because this is the one number in
-- here the player is also reading -- it is the clock in the top of the HUD.
Spawner.BOSS_AT = 600

-- What the boss fight spawns alongside the boss. Eyes only, because the boss is
-- an eye: what arrives with it reads as its own rather than as the horde
-- carrying on, and a shooter is the thing that punishes standing still, which is
-- what you would otherwise do while emptying a magazine into something big. Kept
-- to a handful at a time so the fight stays a fight rather than a wave.
local ESCORT_KIND = "eye"
local ESCORT_EVERY = 2.6
local ESCORT_MAX = 10

-- What one cycle adds to the horde. Both are compounding, and both are read as
-- an exponent of *where the run has got to* rather than stepped on at the
-- boundary (Spawner:scale) -- so hp climbs smoothly through the ten minutes and
-- carries on climbing through the next ten, while damage steps once a cycle. hp
-- can afford to be continuous because a tougher blob is a longer fight; damage
-- cannot, because a blob that hits for a fraction more every minute is a blob
-- nobody can learn.
local HP_PER_CYCLE = 1.4
local DAMAGE_PER_CYCLE = 1.18

-- { kind, unlocked at (seconds), weight }
local TABLE = {
    { "blob",  0,   10 },
    { "bat",   60,  7 },
    { "skull", 300, 3 },
    { "eye",    450, 2 },
    { "redeye", 600, 1 },
}

function Spawner.new()
    return setmetatable({
        timer = 0,
        phase = "waves",  -- waves -> boss, and back round on an endless run
        cycle = 1,
        cycleStart = 0,   -- when this cycle's ten minutes began
        escortT = 0,
    }, Spawner)
end

function Spawner:bossAt()
    return self.cycleStart + Spawner.BOSS_AT
end

-- How far through this cycle's ten minutes the run is, 0 to 1. It sticks at 1
-- for the length of the boss fight, which is what stops the escort quietly
-- getting tougher while you are busy.
function Spawner:progress(time)
    return util.clamp((time - self.cycleStart) / Spawner.BOSS_AT, 0, 1)
end

-- What a monster spawned right now is worth, as multipliers on the numbers
-- written in Enemy.types. One curve for the whole run rather than a first-ten-
-- minutes ramp and a separate endless one: the exponent is cycles completed plus
-- how far through this one we are, so hp rises by 40% over the first cycle and
-- then goes on rising from there without a step at the join.
function Spawner:scale(time)
    local through = self.cycle - 1 + self:progress(time)
    return {
        hp = HP_PER_CYCLE ^ through,
        damage = DAMAGE_PER_CYCLE ^ (self.cycle - 1),
    }
end

function Spawner:pick(time)
    local total = 0
    for _, row in ipairs(TABLE) do
        if time >= row[2] then total = total + row[3] end
    end

    local roll = love.math.random() * total
    for _, row in ipairs(TABLE) do
        if time >= row[2] then
            roll = roll - row[3]
            if roll <= 0 then return row[1] end
        end
    end
    return TABLE[1][1]
end

-- The ring itself. A phone screen is wider than the 320x180 this was drawn for,
-- so it has to clear the corner of whatever canvas we actually got.
function Spawner:ring(game)
    return math.max(SPAWN_RADIUS,
        util.len(game.vw, game.vh) / 2 + SPAWN_CLEARANCE)
end

-- One enemy, somewhere on the offscreen ring.
function Spawner:drop(game, ring, kind)
    local a = love.math.random() * math.pi * 2
    local r = ring + love.math.random() * 24
    game:spawnEnemy(
        kind or self:pick(game.time),
        game.player.x + math.cos(a) * r,
        game.player.y + math.sin(a) * r)
end

-- The boss walks on from the ring like everything else, and that is deliberate:
-- there is no arena and no arrival animation, just the moment you notice that
-- what came over the edge this time is enormous.
function Spawner:sendBoss(game)
    self.phase = "boss"
    self.escortT = ESCORT_EVERY
    self:drop(game, self:ring(game) + 20, "bosseye")
end

-- The boss is down and the run went on rather than ending. The next cycle's ten
-- minutes start now, so the pause the fight took is not deducted from them.
function Spawner:nextCycle(game)
    self.cycle = self.cycle + 1
    self.cycleStart = game.time
    self.phase = "waves"
    self.timer = 0
end

-- The boss fight: no horde at all, a slow drip of eyes, and nothing to do with
-- the difficulty clock. The floor and the waves are what make the page fill up
-- over ten minutes, and both of them running under a boss would mean the boss
-- was never the thing you were fighting.
function Spawner:updateBoss(dt, game)
    self.escortT = self.escortT - dt
    if self.escortT > 0 then return end
    self.escortT = ESCORT_EVERY

    if #game.enemies < ESCORT_MAX then
        self:drop(game, self:ring(game), ESCORT_KIND)
    end
end

function Spawner:update(dt, game)
    if self.phase == "boss" then
        self:updateBoss(dt, game)
        return
    end

    if game.time >= self:bossAt() then
        self:sendBoss(game)
        return
    end

    -- The difficulty clock runs at 0.4x real time, so the pressure at minute
    -- ten is what a full-speed clock would have reached by minute four. Every
    -- knob below (floor, interval, batch) reads this, not game.time, so the
    -- whole ramp slows together; enemy *unlocks* in TABLE still go by real time.
    -- It is the run's clock rather than the cycle's: an endless run does not
    -- start its horde over, it starts its horde where the last cycle left it.
    local time = game.time * 0.4

    local ring = self:ring(game)

    -- The floor, checked every frame whatever the wave timer says.
    local least = math.min(math.floor(time * FLOOR_RATE), MAX_ENEMIES)
    for _ = 1, math.min(least - #game.enemies, REFILL) do
        self:drop(game, ring)
    end

    -- The waves, on their own timer, on top of whatever the floor is holding.
    self.timer = self.timer - dt
    if self.timer > 0 then return end
    self.timer = math.max(0.22, 1.1 - time * 0.008)

    local batch = 1 + math.floor(time / 25)
    for _ = 1, batch do
        if #game.enemies >= MAX_ENEMIES then break end
        self:drop(game, ring)
    end
end

return Spawner
