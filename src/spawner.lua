-- Drops enemies on a ring just outside the camera so they always walk on from
-- offscreen, and slowly turns up the pressure as the run goes on.

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

-- { kind, unlocked at (seconds), weight }
local TABLE = {
    { "blob",  0,   10 },
    { "bat",   60,  7 },
    { "skull", 300, 3 },
    { "eye",    450, 2 },
    { "redeye", 600, 1 },
}

function Spawner.new()
    return setmetatable({ timer = 0 }, Spawner)
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

-- One enemy, somewhere on the offscreen ring.
function Spawner:drop(game, ring)
    local a = love.math.random() * math.pi * 2
    local r = ring + love.math.random() * 24
    game:spawnEnemy(
        self:pick(game.time),
        game.player.x + math.cos(a) * r,
        game.player.y + math.sin(a) * r)
end

function Spawner:update(dt, game)
    -- The difficulty clock runs at 0.4x real time, so the pressure at minute
    -- ten is what a full-speed clock would have reached by minute four. Every
    -- knob below (floor, interval, batch) reads this, not game.time, so the
    -- whole ramp slows together; enemy *unlocks* in TABLE still go by real time.
    local time = game.time * 0.4

    -- A phone screen is wider than the 320x180 this ring was drawn for, so the
    -- ring has to clear the corner of whatever canvas we actually got.
    local ring = math.max(SPAWN_RADIUS,
        util.len(game.vw, game.vh) / 2 + SPAWN_CLEARANCE)

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
